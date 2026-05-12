/**
 * Service Météo
 * AgroSmart - Système Agricole Intelligent
 *
 * Intégration avec la plateforme IoT voisilab (meteo.voisilab.online)
 * Remplace Open-Meteo par les capteurs physiques déployés en CI.
 */

const axios = require('axios');
const config = require('../config');
const logger = require('../utils/logger');
const prisma = require('../config/prisma');

const BASE_URL = config.weather?.apiUrl || 'https://meteo.voisilab.online/api';
const REQUEST_TIMEOUT = 10000;
const CACHE_DURATION = 30 * 60 * 1000;      // 30 min — données capteur
const NODES_CACHE_DURATION = 60 * 60 * 1000; // 1h — liste des stations

class WeatherService {
  constructor() {
    this.cache = new Map();
    this.nodesCache = null;
    this.nodesCacheTs = 0;
  }

  // ─── Gestion des stations IoT ─────────────────────────────────────────────

  async getNodes() {
    if (this.nodesCache && Date.now() - this.nodesCacheTs < NODES_CACHE_DURATION) {
      return this.nodesCache;
    }
    const response = await axios.get(`${BASE_URL}/nodes`, { timeout: REQUEST_TIMEOUT });
    this.nodesCache = response.data.data;
    this.nodesCacheTs = Date.now();
    return this.nodesCache;
  }

  haversineDistance(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  async getNearestNode(lat, lon) {
    const nodes = await this.getNodes();
    let nearest = nodes[0];
    let minDist = Infinity;
    for (const node of nodes) {
      const dist = this.haversineDistance(lat, lon, node.latitude, node.longitude);
      if (dist < minDist) {
        minDist = dist;
        nearest = node;
      }
    }
    return nearest;
  }

  // ─── Cache helpers ────────────────────────────────────────────────────────

  fromCache(key) {
    const entry = this.cache.get(key);
    if (entry && Date.now() - entry.timestamp < CACHE_DURATION) return entry.data;
    return null;
  }

  toCache(key, data) {
    this.cache.set(key, { timestamp: Date.now(), data });
  }

  // ─── Météo actuelle ───────────────────────────────────────────────────────

  async getCurrentWeather(lat, lon) {
    const cacheKey = `current_${lat}_${lon}`;
    const cached = this.fromCache(cacheKey);
    if (cached) return cached;

    try {
      const node = await this.getNearestNode(parseFloat(lat), parseFloat(lon));
      const response = await axios.get(`${BASE_URL}/sensor-data`, {
        params: { node_id: node.id, limit: 1 },
        timeout: REQUEST_TIMEOUT
      });

      const reading = response.data.data[0];
      if (!reading) throw new Error(`Aucune donnée disponible pour la station ${node.id}`);

      const data = this.formatCurrentWeather(reading, node);
      this.toCache(cacheKey, data);
      return data;
    } catch (error) {
      logger.error('Erreur récupération météo actuelle', { error: error.message, lat, lon });
      throw new Error('Impossible de récupérer les données météo');
    }
  }

  // ─── Prévisions ───────────────────────────────────────────────────────────

  async getForecast(lat, lon) {
    const cacheKey = `forecast_${lat}_${lon}`;
    const cached = this.fromCache(cacheKey);
    if (cached) return cached;

    try {
      const node = await this.getNearestNode(parseFloat(lat), parseFloat(lon));
      const [currentRes, predictRes] = await Promise.all([
        axios.get(`${BASE_URL}/sensor-data`, {
          params: { node_id: node.id, limit: 1 },
          timeout: REQUEST_TIMEOUT
        }),
        axios.get(`${BASE_URL}/ai/predict/${node.id}`, { timeout: REQUEST_TIMEOUT })
      ]);

      const currentReading = currentRes.data.data[0];
      const predictions = predictRes.data.data;

      if (!currentReading) throw new Error(`Aucune donnée disponible pour la station ${node.id}`);

      const data = this.formatForecast(currentReading, predictions, node);
      this.toCache(cacheKey, data);
      return data;
    } catch (error) {
      logger.error('Erreur récupération prévisions', { error: error.message, lat, lon });
      throw new Error('Impossible de récupérer les prévisions météo');
    }
  }

  // ─── Alertes agricoles ────────────────────────────────────────────────────

  async getAgriculturalAlerts(lat, lon) {
    const current = await this.getCurrentWeather(lat, lon);
    const node = await this.getNearestNode(parseFloat(lat), parseFloat(lon));
    const alerts = [];

    // Alertes remontées par la plateforme IoT
    try {
      const response = await axios.get(`${BASE_URL}/alerts`, { timeout: REQUEST_TIMEOUT });
      const platformAlerts = response.data.data.filter(
        a => a.node_id === node.id && a.acknowledged === 0
      );
      for (const alert of platformAlerts.slice(0, 5)) {
        alerts.push({
          type: alert.type.toLowerCase(),
          niveau: alert.severity,
          message: alert.message
        });
      }
    } catch (error) {
      logger.warn('Impossible de récupérer les alertes plateforme', { error: error.message });
    }

    // Alertes dérivées des conditions actuelles
    if (current.temperature > 35) {
      alerts.push({
        type: 'chaleur',
        niveau: 'warning',
        message: `Température élevée (${current.temperature}°C). Évitez les travaux aux heures chaudes et hydratez les cultures.`
      });
    }
    if (current.pluie > 70) {
      alerts.push({
        type: 'pluie',
        niveau: 'warning',
        message: `Fortes précipitations détectées (capteur : ${current.pluie}). Reporter les traitements phytosanitaires.`
      });
    }
    if (current.vent.vitesse > 40) {
      alerts.push({
        type: 'vent',
        niveau: 'warning',
        message: `Vent fort (${current.vent.vitesse} km/h). Reporter les pulvérisations.`
      });
    }
    if (current.anomalie.detectee) {
      alerts.push({
        type: 'anomalie',
        niveau: 'info',
        message: `Anomalie météorologique détectée sur la station ${current.station.nom} (score : ${current.anomalie.score.toFixed(2)}).`
      });
    }

    return alerts;
  }

  // ─── Recommandations d'irrigation ────────────────────────────────────────

  async getIrrigationRecommendations(parcelleId) {
    try {
      const parcelle = await prisma.parcelle.findUnique({
        where: { id: parcelleId },
        include: {
          plantations: {
            where: { statut: 'active' },
            include: { culture: true },
            take: 1
          }
        }
      });

      if (!parcelle) throw new Error('Parcelle non trouvée');

      const culture = parcelle.plantations.length > 0 ? parcelle.plantations[0].culture : null;
      const cultureNom = culture ? culture.nom : 'Culture inconnue';

      const coords = {
        lat: parseFloat(parcelle.latitude) || 5.36,
        lon: parseFloat(parcelle.longitude) || -4.0083
      };

      const [current, forecast] = await Promise.all([
        this.getCurrentWeather(coords.lat, coords.lon),
        this.getForecast(coords.lat, coords.lon)
      ]);

      const lastMesure = await prisma.mesure.findFirst({
        where: {
          capteur: { parcelleId, type: 'HUMIDITE_SOL' }
        },
        orderBy: { timestamp: 'desc' }
      });

      const humiditeSol = lastMesure ? parseFloat(lastMesure.valeur) : 50;

      // ETP approché depuis la température (Hargreaves simplifié pour CI tropical)
      const etp = forecast.previsions[0]?.etp || this.estimateEtp(current.temperature);
      const pluiePrevue = forecast.previsions[0]?.precipitation_totale || 0;
      let besoinIrrigation = etp - pluiePrevue;

      if (humiditeSol > 80) besoinIrrigation = 0;
      else if (humiditeSol < 40) besoinIrrigation *= 1.2;

      besoinIrrigation = Math.max(0, Math.round(besoinIrrigation * 10) / 10);

      let meilleurMoment = 'matin (6h-9h)';
      if (current.temperature < 25) meilleurMoment = 'matinée ou fin d\'après-midi';
      else if (current.temperature > 32) meilleurMoment = 'tôt le matin (5h-7h) ou soir (18h-20h)';

      return {
        parcelle: { id: parcelle.id, nom: parcelle.nom, culture: cultureNom },
        meteo: {
          temperature: current.temperature,
          humidite_air: current.humidite,
          humidite_sol: humiditeSol,
          pluie_prevue: pluiePrevue
        },
        irrigation: {
          etp,
          besoin_eau_mm: besoinIrrigation,
          meilleur_moment: meilleurMoment,
          recommandation: besoinIrrigation > 0
            ? `Irriguer avec environ ${besoinIrrigation} mm d'eau`
            : "Pas d'irrigation nécessaire aujourd'hui"
        },
        alerts: await this.getAgriculturalAlerts(coords.lat, coords.lon)
      };
    } catch (error) {
      logger.error('Erreur calcul recommandations irrigation', { error: error.message, parcelleId });
      throw error;
    }
  }

  // ─── Sauvegarde historique ────────────────────────────────────────────────

  async saveWeatherData(lat, lon) {
    try {
      const current = await this.getCurrentWeather(lat, lon);
      await prisma.meteo.create({
        data: {
          latitude: lat,
          longitude: lon,
          temperature: current.temperature,
          humiditeAir: current.humidite,
          pression: current.pression,
          vitesseVent: current.vent.vitesse,
          directionVent: current.vent.direction,
          description: current.description,
          observationAt: new Date(current.timestamp),
          source: 'voisilab-iot'
        }
      });
      logger.info('Données météo sauvegardées', { lat, lon, station: current.station?.id });
    } catch (error) {
      logger.error('Erreur sauvegarde données météo', { error: error.message });
    }
  }

  // ─── Formatters ───────────────────────────────────────────────────────────

  formatCurrentWeather(reading, node) {
    const weatherCode = this.deriveWeatherCode(
      reading.temperature,
      reading.humidity,
      reading.rain_level
    );
    return {
      temperature: Math.round(reading.temperature * 10) / 10,
      humidite: Math.round(reading.humidity),
      pression: Math.round(reading.pressure),
      vent: {
        vitesse: Math.round(reading.wind_speed * 10) / 10,
        direction: 'N/A'
      },
      pluie: reading.rain_level,
      luminosite: reading.luminosity,
      weather_code: weatherCode,
      description: this.getWeatherDescription(weatherCode),
      icone: this.getWeatherIcon(weatherCode, 1),
      station: { id: node.id, nom: node.name, localisation: node.location },
      anomalie: {
        score: reading.anomaly_score,
        detectee: reading.is_anomaly === 1
      },
      timestamp: new Date(reading.timestamp * 1000)
    };
  }

  formatForecast(currentReading, predictions, node) {
    const now = new Date();
    const previsions = predictions.map(pred => {
      const date = new Date(now.getTime() + pred.horizon_hours * 60 * 60 * 1000);
      const dateStr = date.toISOString().split('T')[0];
      // Estimation du niveau de pluie prévu : atténué si probabilité d'événement extrême est faible
      const rainEstimate = currentReading.rain_level * (1 - pred.extreme_event_probability * 0.5);
      const weatherCode = this.deriveWeatherCode(
        pred.predicted_temp,
        pred.predicted_humidity,
        rainEstimate
      );
      const tempVariation = pred.predicted_temp * 0.05;

      return {
        date: dateStr,
        horizon_heures: pred.horizon_hours,
        temp_min: Math.round((pred.predicted_temp - tempVariation) * 10) / 10,
        temp_max: Math.round((pred.predicted_temp + tempVariation) * 10) / 10,
        temp_moyenne: Math.round(pred.predicted_temp * 10) / 10,
        humidite: Math.round(pred.predicted_humidity),
        pression: Math.round(pred.predicted_pressure),
        precipitation_totale: 0, // Non fourni par la plateforme IoT
        probabilite_pluie: Math.round(pred.extreme_event_probability * 100),
        etp: this.estimateEtp(pred.predicted_temp),
        uv_index: null,
        vitesse_vent: Math.round(currentReading.wind_speed * 10) / 10,
        direction_vent: 'N/A',
        weather_code: weatherCode,
        description: this.getWeatherDescription(weatherCode),
        icone: this.getWeatherIcon(weatherCode, 1)
      };
    });

    return {
      latitude: node.latitude,
      longitude: node.longitude,
      station: { id: node.id, nom: node.name, localisation: node.location },
      previsions
    };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /**
   * Derive un code WMO approximatif à partir des valeurs capteurs.
   * Permet de réutiliser le mapping icônes/descriptions existant.
   */
  deriveWeatherCode(temperature, humidity, rainLevel) {
    if (rainLevel > 80) return 65; // pluie forte
    if (rainLevel > 50) return 63; // pluie modérée
    if (rainLevel > 20) return 61; // pluie faible
    if (humidity > 90) return 45;  // brouillard
    if (humidity > 75) return 3;   // couvert
    if (humidity > 60) return 2;   // partiellement nuageux
    if (temperature > 30 && humidity < 50) return 0; // ciel clair
    return 1; // majoritairement clair
  }

  /**
   * Approximation ETP (mm/j) par formule empirique tropicale.
   * Hargreaves simplifié sans données Ra : valide pour le contexte CI.
   */
  estimateEtp(temperature) {
    return Math.round(Math.max(2, Math.min(8, 0.15 * temperature - 1)) * 10) / 10;
  }

  degreesToDirection(degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return directions[Math.round(degrees / 45) % 8];
  }

  getWeatherDescription(wmoCode) {
    const codes = {
      0: 'Ciel clair',
      1: 'Majoritairement clair',
      2: 'Partiellement nuageux',
      3: 'Couvert',
      45: 'Brouillard',
      48: 'Brouillard givrant',
      51: 'Bruine légère',
      53: 'Bruine modérée',
      55: 'Bruine dense',
      61: 'Pluie faible',
      63: 'Pluie modérée',
      65: 'Pluie forte',
      80: 'Averses de pluie faibles',
      81: 'Averses de pluie modérées',
      82: 'Averses de pluie violentes',
      95: 'Orage léger ou modéré',
      99: 'Orage avec grêle forte'
    };
    return codes[wmoCode] || 'Météo variable';
  }

  getWeatherIcon(wmoCode, isDay = 1) {
    const suffix = isDay ? 'd' : 'n';
    if (wmoCode === 0) return `01${suffix}`;
    if (wmoCode === 1) return `02${suffix}`;
    if (wmoCode === 2) return `03${suffix}`;
    if (wmoCode === 3) return `04${suffix}`;
    if ([45, 48].includes(wmoCode)) return `50${suffix}`;
    if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67].includes(wmoCode)) return `09${suffix}`;
    if ([80, 81, 82].includes(wmoCode)) return `10${suffix}`;
    if ([95, 96, 99].includes(wmoCode)) return `11${suffix}`;
    return `02${suffix}`;
  }

  clearCache() {
    this.cache.clear();
    this.nodesCache = null;
    this.nodesCacheTs = 0;
  }
}

module.exports = new WeatherService();
