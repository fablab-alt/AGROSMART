/**
 * Routes du Marketplace
 * AgroSmart - Système Agricole Intelligent
 */

const express = require('express');
const router = express.Router();
const marketplaceController = require('../controllers/marketplaceController');
const {
  authenticate,
  isProducteur,
  isPartenaire,
  isConseiller,
  isAdmin,
  isMarketplaceUser,
  schemas,
  body,
  validate
} = require('../middlewares');
const multer = require('multer');

// Configuration multer pour les images de produits
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024, files: 5 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Seules les images sont acceptées'), false);
    }
  }
});

/* ========== ROUTES PUBLIQUES (sans authentification) ========== */

/**
 * @route   GET /api/marketplace/produits
 * @desc    Lister les produits disponibles
 * @access  Public (consultation sans authentification)
 */
router.get('/produits', schemas.pagination, marketplaceController.getAllProduits);

/**
 * @route   GET /api/marketplace/produits/search
 * @desc    Rechercher des produits
 * @access  Public (consultation sans authentification)
 */
router.get('/produits/search', marketplaceController.searchProduits);

/**
 * @route   GET /api/marketplace/produits/mes-produits
 * @desc    Lister mes produits en vente
 * @access  Producteur, Partenaire
 * NOTE: Must be BEFORE /produits/:id to avoid :id capturing 'mes-produits'
 */
router.get('/produits/mes-produits', authenticate, isProducteur, schemas.pagination, marketplaceController.getMyProduits);

/**
 * @route   GET /api/marketplace/produits/:id
 * @desc    Obtenir un produit par son ID
 * @access  Public (consultation sans authentification)
 */
router.get('/produits/:id', schemas.paramUuid('id'), marketplaceController.getProduitById);

/* ========== ROUTES PROTÉGÉES (authentification requise) ========== */
router.use(authenticate);

/**
 * @route   POST /api/marketplace/produits
 * @desc    Ajouter un produit à vendre
 * @access  Producteur, Partenaire
 */
router.post('/produits',
  isProducteur,
  upload.array('images', 5),
  [
    body('nom').trim().notEmpty().isLength({ max: 100 }),
    body('description').optional().trim().isLength({ max: 2000 }),
    body('categorie')
      .isIn(['cereale', 'legume', 'fruit', 'tubercule', 'oleagineux', 'intrant', 'equipement', 'service', 'autre']),
    body('prix').isFloat({ min: 0 }),
    body('unite').optional().isIn(['kg', 'tonne', 'unite', 'sac', 'litre', 'jour']),
    body('quantite_disponible').isFloat({ min: 0 }),
    body('type_offre').optional().isIn(['vente', 'location']),
    body('prix_location_jour').optional().isFloat({ min: 0 }),
    body('localisation').optional().trim().isLength({ max: 255 }),
    validate
  ],
  marketplaceController.createProduit
);

/**
 * @route   PUT /api/marketplace/produits/:id
 * @desc    Mettre à jour un produit
 * @access  Propriétaire, Admin
 */
router.put('/produits/:id', schemas.paramUuid('id'), upload.array('images', 5), marketplaceController.updateProduit);

/**
 * @route   DELETE /api/marketplace/produits/:id
 * @desc    Supprimer un produit
 * @access  Propriétaire, Admin
 */
router.delete('/produits/:id', schemas.paramUuid('id'), marketplaceController.deleteProduit);

/* ========== COMMANDES ========== */

/**
 * @route   GET /api/marketplace/commandes
 * @desc    Lister mes commandes (acheteur ou vendeur)
 * @access  Producteur, Partenaire, Acheteur
 */
router.get('/commandes', isMarketplaceUser, schemas.pagination, marketplaceController.getCommandes);

/**
 * @route   POST /api/marketplace/commandes
 * @desc    Passer une commande
 * @access  Producteur, Partenaire, Acheteur
 */
router.post('/commandes',
  isMarketplaceUser,
  [
    body('produit_id').isUUID(),
    body('quantite').isFloat({ min: 0.01 }),
    body('adresse_livraison').optional().trim().isLength({ max: 500 }),
    body('notes').optional().trim().isLength({ max: 500 }),
    body('date_debut').optional().isISO8601(),
    body('date_fin').optional().isISO8601(),
    validate
  ],
  marketplaceController.createCommande
);

/**
 * @route   GET /api/marketplace/commandes/:id
 * @desc    Obtenir une commande par son ID
 * @access  Acheteur, Vendeur, Admin
 */
router.get('/commandes/:id', schemas.paramUuid('id'), marketplaceController.getCommandeById);

/**
 * @route   PUT /api/marketplace/commandes/:id/status
 * @desc    Mettre à jour le statut d'une commande
 * @access  Vendeur, Admin
 */
router.put('/commandes/:id/status',
  [
    body('statut')
      .isIn([
        'en_attente',
        'confirmee',
        'en_preparation',
        'expediee',
        'livree',
        'annulee',
        'PENDING',
        'CONFIRMED',
        'SHIPPED',
        'DELIVERED',
        'CANCELLED'
      ])
      .withMessage('Statut invalide'),
    body('notes').optional().trim().isLength({ max: 500 }),
    validate
  ],
  marketplaceController.updateCommandeStatus
);

/**
 * @route   PUT /api/marketplace/commandes/:id/cancel
 * @desc    Annuler une commande
 * @access  Acheteur, Vendeur, Admin
 */
router.put('/commandes/:id/cancel',
  [
    body('raison').optional().trim().isLength({ max: 500 }),
    validate
  ],
  marketplaceController.cancelCommande
);

/* ========== STATISTIQUES ========== */

/**
 * @route   GET /api/marketplace/stats
 * @desc    Statistiques du marketplace
 * @access  Conseiller, Admin
 */
router.get('/stats', isConseiller, marketplaceController.getStats);

/**
 * @route   GET /api/marketplace/stats/vendeur
 * @desc    Statistiques pour un vendeur
 * @access  Producteur, Partenaire
 */
router.get('/stats/vendeur', isProducteur, marketplaceController.getVendeurStats);

module.exports = router;
