/**
 * Routes pour la gestion des stocks agricoles
 * AgroSmart - Système Agricole Intelligent
 */

const express = require('express');
const router = express.Router();
const stockController = require('../controllers/stockController');
const { authenticate } = require('../middlewares/auth');
const { validate } = require('../middlewares/validation');
const { body, param, query } = require('express-validator');

// Toutes les routes nécessitent l'authentification
router.use(authenticate);

// Validation pour la création de stock
const createStockValidation = [
  body('nom')
    .notEmpty()
    .withMessage('Le nom du stock est requis')
    .isLength({ max: 200 })
    .withMessage('Le nom ne doit pas dépasser 200 caractères'),
  body('categorie')
    .notEmpty()
    .withMessage('La catégorie est requise')
    .isIn(['SEMENCES', 'ENGRAIS', 'PESTICIDES', 'HERBICIDES', 'OUTILS', 'RECOLTES', 'AUTRES'])
    .withMessage('Catégorie invalide'),
  body('type')
    .notEmpty()
    .withMessage('Le type est requis')
    .isLength({ max: 100 })
    .withMessage('Le type ne doit pas dépasser 100 caractères'),
  body('quantite')
    .notEmpty()
    .withMessage('La quantité est requise')
    .isFloat({ min: 0 })
    .withMessage('La quantité doit être un nombre positif'),
  body('unite')
    .notEmpty()
    .withMessage('L\'unité est requise')
    .isLength({ max: 20 })
    .withMessage('L\'unité ne doit pas dépasser 20 caractères'),
  body('seuilAlerte')
    .notEmpty()
    .withMessage('Le seuil d\'alerte est requis')
    .isFloat({ min: 0 })
    .withMessage('Le seuil d\'alerte doit être un nombre positif'),
  body('parcelleId')
    .optional()
    .isUUID()
    .withMessage('ID de parcelle invalide'),
  body('prixUnitaire')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Le prix unitaire doit être un nombre positif'),
  body('dateAchat')
    .optional()
    .isISO8601()
    .withMessage('Format de date invalide'),
  body('dateExpiration')
    .optional()
    .isISO8601()
    .withMessage('Format de date invalide'),
  body('fournisseur')
    .optional()
    .isLength({ max: 200 })
    .withMessage('Le fournisseur ne doit pas dépasser 200 caractères'),
  body('localisation')
    .optional()
    .isLength({ max: 200 })
    .withMessage('La localisation ne doit pas dépasser 200 caractères'),
];

// Validation pour les mouvements de stock
const mouvementValidation = [
  body('typeMouvement')
    .notEmpty()
    .withMessage('Le type de mouvement est requis')
    .isIn(['ENTREE', 'SORTIE', 'AJUSTEMENT', 'PERTE'])
    .withMessage('Type de mouvement invalide'),
  body('quantite')
    .notEmpty()
    .withMessage('La quantité est requise')
    .isFloat({ min: 0 })
    .withMessage('La quantité doit être un nombre positif'),
  body('motif')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('Le motif ne doit pas dépasser 1000 caractères'),
  body('reference')
    .optional()
    .isLength({ max: 100 })
    .withMessage('La référence ne doit pas dépasser 100 caractères'),
];

// Routes
router.get('/statistiques', stockController.getStatistiques);
router.get('/', stockController.getStocks);
router.get('/:id', param('id').isUUID(), validate, stockController.getStockById);
router.post('/', createStockValidation, validate, stockController.createStock);
router.put('/:id', param('id').isUUID(), validate, stockController.updateStock);
router.delete('/:id', param('id').isUUID(), validate, stockController.deleteStock);

// Mouvements de stock
router.post(
  '/:id/mouvement',
  param('id').isUUID(),
  mouvementValidation,
  validate,
  stockController.addMouvement
);

// Alertes
router.get(
  '/:id/alertes',
  param('id').isUUID(),
  validate,
  stockController.getAlertes
);
router.patch(
  '/:id/alertes/:alerteId/marquer-lue',
  param('id').isUUID(),
  param('alerteId').isUUID(),
  validate,
  stockController.marquerAlerteLue
);

module.exports = router;
