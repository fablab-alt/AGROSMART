/**
 * Routes Calendrier Agricole
 */

const express = require('express');
const router = express.Router();
const calendrierController = require('../controllers/calendrierController');
const { authenticate } = require('../middlewares/auth');
const { body, query, param } = require('express-validator');
const { validate } = require('../middlewares/validation');

// Toutes les routes nécessitent une authentification
router.use(authenticate);

/**
 * @route   GET /api/v1/calendrier
 * @desc    Obtenir toutes les activités du calendrier
 * @access  Private
 */
router.get('/',
  [
    query('parcelleId').optional().isUUID().withMessage('ID parcelle invalide'),
    query('typeActivite').optional().isIn([
      'SEMIS', 'PLANTATION', 'ARROSAGE', 'FERTILISATION', 
      'TRAITEMENT', 'DESHERBAGE', 'TAILLE', 'RECOLTE', 'AUTRE'
    ]),
    query('statut').optional().isIn(['PLANIFIEE', 'EN_COURS', 'TERMINEE', 'ANNULEE', 'REPORTEE']),
    query('priorite').optional().isIn(['BASSE', 'MOYENNE', 'HAUTE', 'URGENTE']),
    query('dateDebut').optional().isISO8601().withMessage('Format de date invalide'),
    query('dateFin').optional().isISO8601().withMessage('Format de date invalide'),
    query('page').optional().isInt({ min: 1 }).withMessage('Page invalide'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit invalide'),
    validate
  ],
  calendrierController.getActivites
);

/**
 * @route   GET /api/v1/calendrier/prochaines
 * @desc    Obtenir les activités à venir
 * @access  Private
 */
router.get('/prochaines',
  [
    query('jours').optional().isInt({ min: 1, max: 30 }).withMessage('Nombre de jours invalide'),
    validate
  ],
  calendrierController.getActivitesProchaines
);

/**
 * @route   GET /api/v1/calendrier/statistiques
 * @desc    Obtenir les statistiques du calendrier
 * @access  Private
 */
router.get('/statistiques', calendrierController.getStatistiques);

/**
 * @route   GET /api/v1/calendrier/:id
 * @desc    Obtenir une activité par ID
 * @access  Private
 */
router.get('/:id',
  [
    param('id').isUUID().withMessage('ID invalide'),
    validate
  ],
  calendrierController.getActiviteById
);

/**
 * @route   POST /api/v1/calendrier
 * @desc    Créer une nouvelle activité
 * @access  Private
 */
router.post('/',
  [
    body('titre')
      .notEmpty().withMessage('Le titre est requis')
      .isLength({ max: 255 }).withMessage('Titre trop long'),
    body('typeActivite')
      .isIn(['SEMIS', 'PLANTATION', 'ARROSAGE', 'FERTILISATION', 'TRAITEMENT', 'DESHERBAGE', 'TAILLE', 'RECOLTE', 'AUTRE'])
      .withMessage('Type d\'activité invalide'),
    body('priorite')
      .optional()
      .isIn(['BASSE', 'MOYENNE', 'HAUTE', 'URGENTE'])
      .withMessage('Priorité invalide'),
    body('dateDebut')
      .notEmpty().withMessage('La date de début est requise')
      .isISO8601().withMessage('Format de date invalide'),
    body('dateFin')
      .optional()
      .isISO8601().withMessage('Format de date invalide'),
    body('dateRappel')
      .optional()
      .isISO8601().withMessage('Format de date invalide'),
    body('parcelleId')
      .optional()
      .isUUID().withMessage('ID parcelle invalide'),
    body('estRecurrente')
      .optional()
      .isBoolean().withMessage('estRecurrente doit être un booléen'),
    body('frequenceJours')
      .optional()
      .isInt({ min: 1 }).withMessage('Fréquence invalide'),
    body('coutEstime')
      .optional()
      .isFloat({ min: 0 }).withMessage('Coût invalide'),
    body('produitsUtilises')
      .optional()
      .isArray().withMessage('produitsUtilises doit être un tableau'),
    validate
  ],
  calendrierController.createActivite
);

/**
 * @route   PUT /api/v1/calendrier/:id
 * @desc    Mettre à jour une activité
 * @access  Private
 */
router.put('/:id',
  [
    param('id').isUUID().withMessage('ID invalide'),
    body('titre')
      .optional()
      .isLength({ max: 255 }).withMessage('Titre trop long'),
    body('typeActivite')
      .optional()
      .isIn(['SEMIS', 'PLANTATION', 'ARROSAGE', 'FERTILISATION', 'TRAITEMENT', 'DESHERBAGE', 'TAILLE', 'RECOLTE', 'AUTRE'])
      .withMessage('Type d\'activité invalide'),
    body('statut')
      .optional()
      .isIn(['PLANIFIEE', 'EN_COURS', 'TERMINEE', 'ANNULEE', 'REPORTEE'])
      .withMessage('Statut invalide'),
    body('priorite')
      .optional()
      .isIn(['BASSE', 'MOYENNE', 'HAUTE', 'URGENTE'])
      .withMessage('Priorité invalide'),
    body('dateDebut')
      .optional()
      .isISO8601().withMessage('Format de date invalide'),
    body('dateFin')
      .optional()
      .isISO8601().withMessage('Format de date invalide'),
    body('dateRappel')
      .optional()
      .isISO8601().withMessage('Format de date invalide'),
    body('coutEstime')
      .optional()
      .isFloat({ min: 0 }).withMessage('Coût invalide'),
    body('produitsUtilises')
      .optional()
      .isArray().withMessage('produitsUtilises doit être un tableau'),
    validate
  ],
  calendrierController.updateActivite
);

/**
 * @route   PATCH /api/v1/calendrier/:id/terminer
 * @desc    Marquer une activité comme terminée
 * @access  Private
 */
router.patch('/:id/terminer',
  [
    param('id').isUUID().withMessage('ID invalide'),
    validate
  ],
  calendrierController.marquerTerminee
);

/**
 * @route   DELETE /api/v1/calendrier/:id
 * @desc    Supprimer une activité
 * @access  Private
 */
router.delete('/:id',
  [
    param('id').isUUID().withMessage('ID invalide'),
    validate
  ],
  calendrierController.deleteActivite
);

module.exports = router;
