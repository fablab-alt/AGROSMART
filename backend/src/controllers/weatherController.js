/**
 * Weather Controller
 * AgroSmart - Système Agricole Intelligent
 *
 * Délègue au WeatherService (plateforme IoT voisilab).
 */

const weatherService = require('../services/weatherService');
const logger = require('../utils/logger');

/**
 * GET /api/v1/weather/current
 * GET /api/v1/weather/current/:lat/:lon
 */
exports.getCurrentWeather = async (req, res, next) => {
  try {
    const lat = parseFloat(req.params.lat || req.query.lat) || 5.36;
    const lon = parseFloat(req.params.lon || req.query.lon) || -4.0083;

    const weather = await weatherService.getCurrentWeather(lat, lon);

    // Sauvegarde asynchrone — ne bloque pas la réponse
    weatherService.saveWeatherData(lat, lon).catch(() => {});

    res.json({
      success: true,
      source: 'voisilab-iot',
      data: {
        location: weather.station?.localisation || 'Position actuelle',
        station: weather.station?.nom || 'Station météo',
        temperature: weather.temperature,
        humidity: weather.humidite,
        pressure: weather.pression,
        wind_speed: weather.vent.vitesse,
        wind_direction: weather.vent.direction,
        rain_level: weather.pluie,
        luminosity: weather.luminosite,
        weather_code: weather.weather_code,
        condition: weather.description,
        icon: weather.icone,
        anomalie: weather.anomalie,
        timestamp: weather.timestamp
      }
    });
  } catch (error) {
    logger.error('Erreur récupération météo actuelle', { message: error.message });
    next(error);
  }
};

/**
 * GET /api/v1/weather/forecast
 * GET /api/v1/weather/forecast/:lat/:lon
 *
 * Retourne les prévisions IA à 4 horizons (3h, 6h, 12h, 24h)
 * depuis la station IoT la plus proche.
 */
exports.getForecast = async (req, res, next) => {
  try {
    const lat = parseFloat(req.params.lat || req.query.lat) || 5.36;
    const lon = parseFloat(req.params.lon || req.query.lon) || -4.0083;

    const data = await weatherService.getForecast(lat, lon);

    res.json({
      success: true,
      source: 'voisilab-iot',
      station: data.station,
      data: {
        daily: data.previsions.map(p => ({
          date: p.date,
          horizon_heures: p.horizon_heures,
          temp_min: p.temp_min,
          temp_max: p.temp_max,
          temp_moyenne: p.temp_moyenne,
          weather_code: p.weather_code,
          description: p.description,
          icon: p.icone,
          humidity: p.humidite,
          pressure: p.pression,
          wind_speed: p.vitesse_vent,
          precipitation_probability: p.probabilite_pluie,
          etp: p.etp
        }))
      }
    });
  } catch (error) {
    logger.error('Erreur récupération prévisions', { message: error.message });
    next(error);
  }
};

/**
 * GET /api/v1/weather/alerts
 * GET /api/v1/weather/alerts/:lat/:lon
 */
exports.getWeatherAlerts = async (req, res, next) => {
  try {
    const lat = parseFloat(req.params.lat || req.query.lat) || 5.36;
    const lon = parseFloat(req.params.lon || req.query.lon) || -4.0083;

    const alerts = await weatherService.getAgriculturalAlerts(lat, lon);

    res.json({ success: true, data: alerts });
  } catch (error) {
    logger.error('Erreur récupération alertes météo', { message: error.message });
    // Dégradation gracieuse : retourne liste vide plutôt qu'une erreur 500
    res.json({
      success: true,
      data: [],
      warning: 'Impossible de récupérer les alertes météo'
    });
  }
};

module.exports = exports;
