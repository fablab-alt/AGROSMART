/**
 * Weather Routes - OpenWeather API
 * AgroSmart
 */

const express = require('express');
const router = express.Router();
const weatherController = require('../controllers/weatherController');
const { authenticate } = require('../middlewares/auth');

// Public routes (no auth required for weather data)
// Routes supporting both path params and query params (handled in controller)
router.get('/forecast', weatherController.getForecast);
router.get('/forecast/:lat/:lon', weatherController.getForecast);
router.get('/current', weatherController.getCurrentWeather);
router.get('/current/:lat/:lon', weatherController.getCurrentWeather);
router.get('/alerts', weatherController.getWeatherAlerts);
router.get('/alerts/:lat/:lon', weatherController.getWeatherAlerts);

// Authenticated routes for saving preferences
router.use(authenticate);

// Add more routes as needed (e.g., save favorite locations)

module.exports = router;
