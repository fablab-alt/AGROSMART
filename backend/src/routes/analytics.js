/**
 * Routes d'analytics
 * AgroSmart - Système Agricole Intelligent
 */

const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analyticsController');
const { authenticate, isProducteur } = require('../middlewares');

// Route publique pour les statistiques (Landing page)
router.get('/public', analyticsController.getPublicStats);

// Toutes les autres routes nécessitent une authentification
router.use(authenticate);

/**
 * @route   GET /api/analytics/stats
 * @desc    Obtenir les statistiques globales de la ferme
 * @access  Producteur, Conseiller, Admin
 */
router.get('/stats', isProducteur, analyticsController.getStats);

/**
 * @  route   GET /api/analytics/parcelles/:parcelleId
 * @desc    Obtenir les analytics d'une parcelle spécifique
 * @access  Producteur (propriétaire)
 */
router.get('/parcelles/:parcelleId', isProducteur, analyticsController.getParcelleAnalytics);

/**
 * @route   GET /api/analytics/seasonal-comparison
 * @desc    Comparaison saisonnière des rendements et performances
 * @access  Producteur, Conseiller, Admin
 */
router.get('/seasonal-comparison', isProducteur, analyticsController.getSeasonalComparison);

/**
 * @route   GET /api/analytics/export
 * @desc    Exporter les données analytiques en Excel ou CSV
 * @access  Producteur, Conseiller, Admin
 */
router.get('/export', isProducteur, analyticsController.exportAnalytics);

module.exports = router;
