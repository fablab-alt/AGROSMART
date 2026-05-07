/**
 * Weather Controller - OpenWeather API Integration
 * AgroSmart - Prévisions Météo 10 Jours
 */

const weatherService = require('../services/weatherService');
const logger = require('../utils/logger');

/**
 * Obtenir les prévisions météo (Délègue au WeatherService)
 * GET /api/weather/forecast/:lat/:lon
 * OU
 * GET /api/weather/forecast?lat=...&lon=...
 */
exports.getForecast = async (req, res, next) => {
    try {
        const lat = req.params.lat || req.query.lat || 5.3600;
        const lon = req.params.lon || req.query.lon || -4.0083;

        const data = await weatherService.getForecast(lat, lon);

        res.json({
            success: true,
            source: 'open-meteo',
            data: data.previsions
        });

    } catch (error) {
        logger.error('Error fetching weather forecast:', error.message);
        next(error);
    }
};

/**
 * Obtenir la météo actuelle
 * GET /api/weather/current/:lat/:lon
 * OU
 * GET /api/weather/current?lat=...&lon=...
 */
exports.getCurrentWeather = async (req, res, next) => {
    try {
        const lat = req.params.lat || req.query.lat || 5.3600;
        const lon = req.params.lon || req.query.lon || -4.0083;

        const weather = await weatherService.getCurrentWeather(lat, lon);

        // Sauvegarde gérée dans le service
        await weatherService.saveWeatherData(lat, lon);

        res.json({
            success: true,
            data: {
                // Mapping to match legacy response expected by frontend/mobile
                location: "Position Actuelle",
                temperature: weather.temperature,
                feels_like: weather.temperature, // Open-Meteo basic ne donne pas ressentie immédiatement
                humidity: weather.humidite,
                pressure: weather.pression,
                wind_speed: weather.vent.vitesse,
                wind_direction: weather.vent.direction,
                condition: weather.description,
                icon: weather.icone
            }
        });

    } catch (error) {
        logger.error('Error fetching current weather:', error.message);
        next(error);
    }
};

/**
 * Obtenir les alertes météo pour une localisation
 * GET /api/weather/alerts/:lat/:lon
 */
exports.getWeatherAlerts = async (req, res, next) => {
    try {
        const lat = req.params.lat || req.query.lat || 5.3600;
        const lon = req.params.lon || req.query.lon || -4.0083;
        // const userId = req.user.id; 

        const alerts = await weatherService.getAgriculturalAlerts(lat, lon);

        res.json({
            success: true,
            data: alerts,
            // saved_count: ...
        });

    } catch (error) {
        logger.error('Error fetching weather alerts:', error.message);
        res.json({
            success: true,
            data: [],
            warning: 'Impossible de récupérer les alertes météo'
        });
    }
};

/**
 * Helper: Convertir degrés vent en direction
 */
function degreesToDirection(degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    const index = Math.round(degrees / 45) % 8;
    return directions[index];
}

/**
 * Helper: Déterminer type d'alerte depuis nom événement
 */
function determineAlertType(event) {
    const eventLower = event.toLowerCase();
    if (eventLower.includes('rain') || eventLower.includes('pluie')) return 'pluies_intenses';
    if (eventLower.includes('wind') || eventLower.includes('vent')) return 'vents_violents';
    if (eventLower.includes('heat') || eventLower.includes('chaleur')) return 'temperature_extreme';
    if (eventLower.includes('drought') || eventLower.includes('sécheresse')) return 'secheresse';
    return 'autre';
}

/**
 * Helper: Générer recommandation basée sur alerte
 */
function generateRecommendation(event) {
    const eventLower = event.toLowerCase();
    if (eventLower.includes('rain') || eventLower.includes('pluie')) {
        return 'Protégez vos cultures, vérifiez le drainage. Reportez les traitements phytosanitaires.';
    }
    if (eventLower.includes('wind') || eventLower.includes('vent')) {
        return 'Sécurisez les installations légères. Surveillez les cultures haute sensibles au vent.';
    }
    if (eventLower.includes('heat') || eventLower.includes('chaleur')) {
        return 'Augmentez l\'irrigation. Protégez les jeunes plants. Évitez les travaux lourds.';
    }
    return 'Surveillez l\'évolution et suivez les consignes locales.';
}

module.exports = exports;
