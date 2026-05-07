/**
 * Routes de gestion des parcelles
 * AgroSmart - Système Agricole Intelligent
 */

const express = require('express');
const router = express.Router();
const parcellesController = require('../controllers/parcellesController');
const { 
  authenticate, 
  isProducteur, 
  isConseiller,
  isAdmin,
  requireParcelleAccess,
  schemas 
} = require('../middlewares');

// Toutes les routes nécessitent une authentification
router.use(authenticate);

/**
 * @route   GET /api/parcelles
 * @desc    Lister les parcelles (filtrées selon le rôle)
 * @access  Producteur, Conseiller, Admin
 */
router.get('/', isProducteur, schemas.pagination, parcellesController.getAll);

/**
 * @route   GET /api/parcelles/stats
 * @desc    Statistiques globales des parcelles
 * @access  Conseiller, Admin
 */
router.get('/stats', isConseiller, parcellesController.getStats);

/**
 * @route   GET /api/parcelles/map
 * @desc    Données pour la carte des parcelles
 * @access  Producteur, Conseiller, Admin
 */
router.get('/map', isProducteur, parcellesController.getMapData);

/**
 * @route   POST /api/parcelles
 * @desc    Créer une nouvelle parcelle
 * @access  Producteur, Conseiller, Admin
 */
router.post('/', isProducteur, schemas.createParcelle, parcellesController.create);

/**
 * @route   POST /api/parcelles/recalculate-all-health
 * @desc    Recalculer la santé de toutes les parcelles
 * @access  Admin
 */
router.post('/recalculate-all-health', isAdmin, parcellesController.recalculateAllHealth);

/**
 * @route   GET /api/parcelles/:id
 * @desc    Obtenir une parcelle par son ID
 * @access  Propriétaire, Conseiller, Admin
 */
router.get('/:id', schemas.paramUuid('id'), requireParcelleAccess, parcellesController.getById);

/**
 * @route   PUT /api/parcelles/:id
 * @desc    Mettre à jour une parcelle
 * @access  Propriétaire, Admin
 */
router.put('/:id', schemas.paramUuid('id'), requireParcelleAccess, parcellesController.update);

/**
 * @route   DELETE /api/parcelles/:id
 * @desc    Supprimer une parcelle
 * @access  Propriétaire, Admin
 */
router.delete('/:id', schemas.paramUuid('id'), requireParcelleAccess, parcellesController.delete);

/**
 * @route   GET /api/parcelles/:id/stations
 * @desc    Obtenir les stations d'une parcelle
 * @access  Propriétaire, Conseiller, Admin
 */
router.get('/:id/stations', schemas.paramUuid('id'), requireParcelleAccess, parcellesController.getStations);

/**
 * @route   GET /api/parcelles/:id/mesures
 * @desc    Obtenir l'historique des mesures d'une parcelle
 * @access  Propriétaire, Conseiller, Admin
 */
router.get('/:id/mesures', schemas.paramUuid('id'), requireParcelleAccess, parcellesController.getMesures);

/**
 * @route   GET /api/parcelles/:id/iot-metrics
 * @desc    Obtenir les métriques IoT actuelles d'une parcelle (dernières valeurs par capteur)
 * @access  Propriétaire, Conseiller, Admin
 */
router.get('/:id/iot-metrics', schemas.paramUuid('id'), requireParcelleAccess, parcellesController.getIotMetrics);

/**
 * @route   GET /api/parcelles/:id/alertes
 * @desc    Obtenir les alertes d'une parcelle
 * @access  Propriétaire, Conseiller, Admin
 */
router.get('/:id/alertes', schemas.paramUuid('id'), requireParcelleAccess, parcellesController.getAlertes);

/**
 * @route   GET /api/parcelles/:id/cultures
 * @desc    Obtenir les cultures/plantations d'une parcelle
 * @access  Propriétaire, Conseiller, Admin
 */
router.get('/:id/cultures', schemas.paramUuid('id'), requireParcelleAccess, parcellesController.getCultures);

/**
 * @route   GET /api/parcelles/:id/recommandations
 * @desc    Obtenir les recommandations pour une parcelle
 * @access  Propriétaire, Conseiller, Admin
 */
router.get('/:id/recommandations', schemas.paramUuid('id'), requireParcelleAccess, parcellesController.getRecommandations);

/**
 * @route   GET /api/parcelles/:id/historique
 * @desc    Historique des données d'une parcelle
 * @access  Propriétaire, Conseiller, Admin
 */
router.get('/:id/historique', schemas.paramUuid('id'), requireParcelleAccess, parcellesController.getHistorique);

/**
 * @route   POST /api/parcelles/:id/recalculate-health
 * @desc    Recalculer la santé d'une parcelle à partir des capteurs
 * @access  Propriétaire, Conseiller, Admin
 */
router.post('/:id/recalculate-health', schemas.paramUuid('id'), requireParcelleAccess, parcellesController.recalculateHealth);

module.exports = router;
