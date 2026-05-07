/**
 * Routes de diagnostics
 * AgroSmart - Système Agricole Intelligent
 */

const express = require('express');
const router = express.Router();
const diagnosticsController = require('../controllers/diagnosticsController');
const { authenticate, isProducteur, body, validate, schemas } = require('../middlewares');

const multer = require('multer');

const fs = require('fs');

// Configuration multer
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadDir = 'uploads/diagnostics/';
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = file.mimetype.split('/')[1];
        cb(null, file.fieldname + '-' + uniqueSuffix + '.' + ext);
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
    fileFilter: (req, file, cb) => {
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Seulement les images sont autorisées'));
        }
    }
});

// Toutes les routes nécessitent une authentification
router.use(authenticate);

/**
 * @route   POST /api/diagnostics/analyze
 * @desc    Analyser une image de plante avec le service IA
 * @access  Producteur
 */
router.post('/analyze',
    isProducteur,
    upload.single('image'),
    [
        body('crop_type').optional().trim().isLength({ max: 100 }),
        body('parcelle_id').optional().isUUID(),
        // image_url becomes optional or derived from file
        // body('image_url').optional().trim().isURL(), 
        validate
    ],
    diagnosticsController.analyzePlant
);

/**
 * @route   GET /api/diagnostics/history
 * @desc    Obtenir l'historique des diagnostics
 * @access  Producteur
 */
router.get('/history', isProducteur, diagnosticsController.getHistory);

/**
 * @route   GET /api/diagnostics/:id
 * @desc    Obtenir un diagnostic par son ID
 * @access  Producteur (propriétaire)
 */
router.get('/:id', isProducteur, schemas.paramUuid('id'), diagnosticsController.getDiagnosticById);

module.exports = router;
