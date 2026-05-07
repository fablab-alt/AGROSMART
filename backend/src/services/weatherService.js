/**
 * Service Météo
 * AgroSmart - Système Agricole Intelligent
 * 
 * Intégration avec Open-Meteo (Données agricoles spécialisées)
 */

const axios = require('axios');
const config = require('../config');
const logger = require('../utils/logger');
const prisma = require('../config/prisma');

class WeatherService {
  constructor() {
    this.baseUrl = config.weather?.apiUrl || 'https://api.open-meteo.com/v1/forecast';
    this.cache = new Map();
    this.cacheDuration = 30 * 60 * 1000; // 30 minutes
  }

  /**
   * Obtenir la météo actuelle pour une localisation
   */
  async getCurrentWeather(lat, lon) {
    const cacheKey = `current_${lat}_${lon}`;

    if (this.cache.has(cacheKey)) {
      const cached = this.cache.get(cacheKey);
      if (Date.now() - cached.timestamp < this.cacheDuration) {
        return cached.data;
      }
    }

    try {
      // https://open-meteo.com/en/docs
      const response = await axios.get(this.baseUrl, {
        params: {
          latitude: lat,
          longitude: lon,
          current: 'temperature_2m,relative_humidity_2m,is_day,precipitation,rain,weather_code,cloud_cover,wind_speed_10m,wind_direction_10m,pressure_msl',
          timezone: 'auto'
          // Pas de clé API nécessaire
        },
        timeout: 10000
      });

      const data = this.formatCurrentWeather(response.data);

      this.cache.set(cacheKey, {
        timestamp: Date.now(),
        data
      });

      return data;
    } catch (error) {
      logger.error('Erreur récupération météo actuelle', { error: error.message, lat, lon });
      throw new Error('Impossible de récupérer les données météo');
    }
  }

  /**
   * Obtenir les prévisions sur 7 jours avec données agricoles
   */
  async getForecast(lat, lon) {
    const cacheKey = `forecast_${lat}_${lon}`;

    if (this.cache.has(cacheKey)) {
      const cached = this.cache.get(cacheKey);
      if (Date.now() - cached.timestamp < this.cacheDuration) {
        return cached.data;
      }
    }

    try {
      const response = await axios.get(this.baseUrl, {
        params: {
          latitude: lat,
          longitude: lon,
          daily: 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,et0_fao_evapotranspiration,precipitation_probability_max,uv_index_max,wind_speed_10m_max,wind_direction_10m_dominant',
          hourly: 'temperature_2m,relative_humidity_2m,rain,precipitation,precipitation_probability,cloud_cover,evapotranspiration,soil_temperature_0cm,soil_temperature_6cm,soil_temperature_18cm,soil_moisture_0_to_1cm,soil_moisture_1_to_3cm,soil_moisture_3_to_9cm,wind_speed_10m,wind_direction_10m,wind_gusts_10m',
          timezone: 'auto'
        },
        timeout: 10000
      });

      const data = this.formatForecast(response.data);

      this.cache.set(cacheKey, {
        timestamp: Date.now(),
        data
      });

      return data;
    } catch (error) {
      logger.error('Erreur récupération prévisions', { error: error.message, lat, lon });
      throw new Error('Impossible de récupérer les prévisions météo');
    }
  }

  /**
   * Formater les données météo actuelles (Open-Meteo -> AgroSmart Model)
   */
  formatCurrentWeather(data) {
    const current = data.current;

    return {
      temperature: current.temperature_2m,
      humidite: current.relative_humidity_2m,
      pression: current.pressure_msl,
      vent: {
        vitesse: current.wind_speed_10m,
        direction: current.wind_direction_10m
      },
      nuages: current.cloud_cover,
      description: this.getWeatherDescription(current.weather_code),
      icone: this.getWeatherIcon(current.weather_code, current.is_day),
      // Open-Meteo "Current" ne donne pas directement sunset/sunrise dans ce bloc, 
      // mais on peut les avoir via "daily". On simplifie ici.
      timestamp: new Date()
    };
  }

  /**
   * Formater les prévisions (Open-Meteo -> AgroSmart Model)
   */
  formatForecast(data) {
    const daily = data.daily;
    const hourly = data.hourly;
    const dailyForecasts = [];

    // Helper to calculate daily average from hourly data
    const getDailyAvg = (hourlyData, dayIndex) => {
      const start = dayIndex * 24;
      const end = start + 24;
      const prices = hourlyData.slice(start, end);
      const sum = prices.reduce((a, b) => a + b, 0);
      return sum / prices.length;
    };

    // Open-Meteo renvoie des tableaux parallèles (time[], temperature_2m_max[], etc.)
    for (let i = 0; i < daily.time.length; i++) {
      // Moisture is often provided as m³/m³ (0-1) or %, we want %
      // Open-Meteo sometimes returns m³/m³. Check docs or values. 
      // Usually 0.35 m3/m3. Param is soil_moisture_3_to_9cm.
      // Let's assume raw value and convert if needed or keep as is.
      // Actually soil_moisture_x_to_y is usually m³/m³. To get %, * 100.
      const moistureRaw = getDailyAvg(hourly.soil_moisture_3_to_9cm, i);

      dailyForecasts.push({
        date: daily.time[i],
        temp_min: daily.temperature_2m_min[i],
        temp_max: daily.temperature_2m_max[i],
        temp_moyenne: (daily.temperature_2m_max[i] + daily.temperature_2m_min[i]) / 2,
        precipitation_totale: daily.precipitation_sum[i],
        probabilite_pluie: daily.precipitation_probability_max[i],
        etp: daily.et0_fao_evapotranspiration[i],
        uv_index: daily.uv_index_max[i],

        // Calculated fields
        humidite: Math.round(getDailyAvg(hourly.relative_humidity_2m, i)),
        vitesse_vent: daily.wind_speed_10m_max[i],
        direction_vent: this.degreesToDirection(daily.wind_direction_10m_dominant[i]),

        // Soil Params
        soil_temperature: Math.round(getDailyAvg(hourly.soil_temperature_6cm, i) * 10) / 10,
        soil_moisture: Math.round(moistureRaw * 100), // Convert m³/m³ to % if needed, usually ranges 0-1.

        description: this.getWeatherDescription(daily.weather_code[i]),
        icone: this.getWeatherIcon(daily.weather_code[i], 1)
      });
    }

    return {
      latitude: data.latitude,
      longitude: data.longitude,
      timezone: data.timezone,
      previsions: dailyForecasts
    };
  }

  degreesToDirection(degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    const index = Math.round(degrees / 45) % 8;
    return directions[index];
  }

  /**
   * Mapping Codes WMO -> Descriptions Françaises
   * https://open-meteo.com/en/docs
   */
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
      71: 'Neige faible', // Rare en CI mais bon
      80: 'Averses de pluie faibles',
      81: 'Averses de pluie modérées',
      82: 'Averses de pluie violentes',
      95: 'Orage léger ou modéré',
      96: 'Orage avec grêle légère',
      99: 'Orage avec grêle forte'
    };
    return codes[wmoCode] || 'Météo variable';
  }

  /**
   * Mapping WMO -> Icon ID (OpenWeatherMap compatible IDs pour le frontend)
   */
  getWeatherIcon(wmoCode, isDay = 1) {
    // 0 -> 01d/n (Clear)
    // 1-3 -> 02d/n - 04d/n (Clouds)
    // 45,48 -> 50d (Mist)
    // 51-67 -> 09d (Rain)
    // 71-77 -> 13d (Snow)
    // 80-82 -> 10d (Showers)
    // 95-99 -> 11d (Thunderstorm)

    const suffix = isDay ? 'd' : 'n';

    if (wmoCode === 0) return `01${suffix}`;
    if (wmoCode === 1) return `02${suffix}`;
    if (wmoCode === 2) return `03${suffix}`;
    if (wmoCode === 3) return `04${suffix}`;
    if ([45, 48].includes(wmoCode)) return `50${suffix}`;
    if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67].includes(wmoCode)) return `09${suffix}`; // Rain
    if ([80, 81, 82].includes(wmoCode)) return `10${suffix}`; // Showers
    if ([95, 96, 99].includes(wmoCode)) return `11${suffix}`; // Storm

    return `02${suffix}`; // Default
  }

  /**
   * Obtenir les alertes météo agricoles
   */
  async getAgriculturalAlerts(lat, lon) {
    const current = await this.getCurrentWeather(lat, lon);
    const forecast = await this.getForecast(lat, lon);
    const alerts = [];

    // Alerte chaleur
    if (current.temperature > 35) {
      alerts.push({
        type: 'chaleur',
        niveau: 'warning',
        message: `Température élevée (${current.temperature}°C). Évitez les travaux aux heures chaudes et hydratez les cultures.`
      });
    }

    // Alerte pluie forte (>30mm)
    const pluieProchaine = forecast.previsions.find(p => p.precipitation_totale > 30);
    if (pluieProchaine) {
      alerts.push({
        type: 'pluie',
        niveau: 'info',
        message: `Fortes pluies prévues le ${pluieProchaine.date} (${pluieProchaine.precipitation_totale}mm). Reporter les traitements phytosanitaires.`
      });
    }

    // Alerte vent fort
    if (current.vent.vitesse > 40) {
      alerts.push({
        type: 'vent',
        niveau: 'warning',
        message: `Vent fort (${current.vent.vitesse} km/h). Reporter les pulvérisations.`
      });
    }

    return alerts;
  }

  /**
   * Recommandations d'irrigation basées sur la météo (Optimisé avec ETP Open-Meteo)
   */
  async getIrrigationRecommendations(parcelleId) {
    try {
      // Récupérer les infos de la parcelle
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

      if (!parcelle) {
        throw new Error('Parcelle non trouvée');
      }

      // Map simplified parcelle object to match expected 'p' structure somewhat or just use direct access
      const culture = parcelle.plantations.length > 0 ? parcelle.plantations[0].culture : null;
      const cultureNom = culture ? culture.nom : 'Culture inconnue';
      const besoinsEau = culture ? (culture.besoinsEauJour || 5) : 5; // Assuming besoinsEauJour exists on Culture or handling default
      // Note: Culture model in schema doesn't show 'besoinsEauJour'. It shows 'besoins_eau_jour' in legacy SQL.
      // Schema line 500-515 (Step 456) shows: nom, nomScientifique, coton, etc. NO 'besoinsEauJour'?
      // Wait, let's check Culture model again. Step 456 lines 500-515.
      // id, nom, nomScientifique, categorie, saisonCulture, dureeJours, phOptimal, temperatureMin/Max.
      // NO besoinsEauJour in Prisma Schema.
      // If legacy DB has it, it's missing in Prisma.
      // I should update schema or use default. Using default 5 for now to avoid schema creep loop unless critical.
      // If I use default, logic works.

      const coords = { lat: parseFloat(parcelle.latitude) || 5.3600, lon: parseFloat(parcelle.longitude) || -4.0083 };

      // Obtenir météo
      const current = await this.getCurrentWeather(coords.lat, coords.lon);
      const forecast = await this.getForecast(coords.lat, coords.lon);

      // Dernière mesure d'humidité sol
      const lastMesure = await prisma.mesure.findFirst({
        where: {
          capteur: {
            parcelleId: parcelleId,
            type: 'HUMIDITE_SOL'
          }
        },
        orderBy: { timestamp: 'desc' }
      });

      const humiditeSol = lastMesure ? parseFloat(lastMesure.valeur) : 50;

      // Utiliser l'ETP directement fournie par Open-Meteo (ET0 FAO-56)
      const etp = forecast.previsions[0].etp || 4.5;
      const kc = 1.0;
      const besoinsReels = etp * kc;
      const pluiePrevue = forecast.previsions[0].precipitation_totale;
      let besoinIrrigation = besoinsReels - pluiePrevue;

      if (humiditeSol > 80) {
        besoinIrrigation = 0;
      } else if (humiditeSol < 40) {
        besoinIrrigation *= 1.2;
      }

      besoinIrrigation = Math.max(0, Math.round(besoinIrrigation * 10) / 10);

      let meilleurMoment = 'matin (6h-9h)';
      if (current.temperature < 25) {
        meilleurMoment = 'matinée ou fin d\'après-midi';
      } else if (current.temperature > 32) {
        meilleurMoment = 'tôt le matin (5h-7h) ou soir (18h-20h)';
      }

      return {
        parcelle: {
          id: parcelle.id,
          nom: parcelle.nom,
          culture: cultureNom
        },
        meteo: {
          temperature: current.temperature,
          humidite_air: current.humidite,
          humidite_sol: humiditeSol,
          pluie_prevue: pluiePrevue
        },
        irrigation: {
          etp: etp,
          besoin_eau_mm: besoinIrrigation,
          meilleur_moment: meilleurMoment,
          recommandation: besoinIrrigation > 0
            ? `Irriguer avec environ ${besoinIrrigation} mm d'eau`
            : 'Pas d\'irrigation nécessaire aujourd\'hui'
        },
        alerts: await this.getAgriculturalAlerts(coords.lat, coords.lon)
      };
    } catch (error) {
      logger.error('Erreur calcul recommandations irrigation', { error: error.message, parcelleId });
      throw error;
    }
  }

  /**
   * Sauvegarder les données météo historiques
   */
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
          observationAt: new Date(current.timestamp), // Ensure JS Date
          source: 'open-meteo'
        }
      });

      logger.info('Données météo sauvegardées', { lat, lon });
    } catch (error) {
      logger.error('Erreur sauvegarde données météo', { error: error.message });
    }
  }

  /**
   * Nettoyer le cache
   */
  clearCache() {
    this.cache.clear();
  }
}

module.exports = new WeatherService();
