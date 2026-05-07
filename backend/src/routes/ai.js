/**
 * Routes IA - Prédictions & Heatmaps
 * AgroSmart - Système Agricole Intelligent
 */

const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');
const { authenticate } = require('../middlewares/auth');

router.use(authenticate);

// Carte de chaleur des nuisibles
router.get('/pest-heatmap', aiController.getPestHeatmap);

// Prédiction de rendement par parcelle
router.get('/predict-yield/:parcelleId', aiController.predictYield);

module.exports = router;
