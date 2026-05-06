const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const fileType = require('file-type');
const { authenticate } = require('../middlewares/auth');

// Allowed magic-byte MIME types per fieldname
const ALLOWED_MAGIC_TYPES = {
  formation_video: ['video/mp4', 'video/avi', 'video/quicktime', 'video/x-msvideo'],
  diagnostic_image: ['image/jpeg', 'image/png', 'image/webp'],
  chat_image: ['image/jpeg', 'image/png', 'image/webp'],
  formation_document: [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/zip', // OOXML formats are ZIP-based; file-type may return this
  ],
};

/**
 * Post-upload magic-byte validation middleware.
 * Reads the saved file's actual bytes; rejects and deletes if mismatch.
 */
async function validateMagicBytes(req, res, next) {
  const file = req.file;
  if (!file) return next();

  const allowed = ALLOWED_MAGIC_TYPES[file.fieldname];
  if (!allowed) {
    fs.unlink(file.path, () => {});
    return res.status(400).json({ success: false, message: 'Champ de fichier non reconnu.' });
  }

  try {
    const type = await fileType.fromFile(file.path);
    if (!type || !allowed.includes(type.mime)) {
      fs.unlink(file.path, () => {});
      return res.status(400).json({
        success: false,
        message: 'Le contenu réel du fichier ne correspond pas au type attendu (magic bytes invalides).'
      });
    }
    next();
  } catch {
    fs.unlink(file.path, () => {});
    return res.status(500).json({ success: false, message: 'Erreur lors de la validation du fichier.' });
  }
}

// Configuration Multer pour stockage local
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        let uploadPath = 'uploads/';

        // Sous-dossiers par type
        if (file.fieldname === 'formation_video') uploadPath += 'videos/';
        else if (file.fieldname === 'formation_document') uploadPath += 'documents/';
        else if (file.fieldname === 'diagnostic_image') uploadPath += 'diagnostics/';
        else if (file.fieldname === 'chat_image') uploadPath += 'chat/';
        else uploadPath += 'others/';

        // Créer le dossier s'il n'existe pas
        if (!fs.existsSync(uploadPath)) {
            fs.mkdirSync(uploadPath, { recursive: true });
        }

        cb(null, uploadPath);
    },
    filename: function (req, file, cb) {
        // Nom unique: timestamp-random.ext
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

// Filtres fichiers avec whitelist stricte sur toutes les catégories
const fileFilter = (req, file, cb) => {
    const ext = file.originalname.split('.').pop().toLowerCase();

    if (file.fieldname === 'formation_video') {
        const allowed = ['mp4', 'avi', 'mov'];
        if (!allowed.includes(ext)) {
            return cb(new Error(`Type de fichier non autorisé. Extensions acceptées: ${allowed.join(', ')}`), false);
        }
    } else if (file.fieldname === 'diagnostic_image' || file.fieldname === 'chat_image') {
        const allowed = ['jpg', 'jpeg', 'png', 'webp'];
        if (!allowed.includes(ext)) {
            return cb(new Error(`Type de fichier non autorisé. Extensions acceptées: ${allowed.join(', ')}`), false);
        }
        const allowedMime = ['image/jpeg', 'image/png', 'image/webp'];
        if (!allowedMime.includes(file.mimetype)) {
            return cb(new Error('Type MIME non autorisé pour cette image.'), false);
        }
    } else if (file.fieldname === 'formation_document') {
        const allowed = ['pdf', 'docx', 'doc', 'pptx', 'xlsx'];
        if (!allowed.includes(ext)) {
            return cb(new Error(`Type de fichier non autorisé. Extensions acceptées: ${allowed.join(', ')}`), false);
        }
        const allowedMime = [
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-powerpoint',
            'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ];
        if (!allowedMime.includes(file.mimetype)) {
            return cb(new Error('Type MIME non autorisé pour ce document.'), false);
        }
    } else {
        // Refuser tout type de fichier non reconnu
        return cb(new Error('Champ de fichier non reconnu.'), false);
    }
    cb(null, true);
};

const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: { fileSize: 50 * 1024 * 1024 } // 50MB max
});

router.use(authenticate);

// Route Upload Image Diagnostic
router.post('/diagnostic', upload.single('diagnostic_image'), validateMagicBytes, (req, res) => {
    if (!req.file) {
        return res.status(400).json({ success: false, message: 'Aucun fichier fourni' });
    }
    res.json({
        success: true,
        message: 'Image uploadée avec succès',
        fileUrl: `/uploads/diagnostics/${req.file.filename}`,
        filename: req.file.filename
    });
});

// Route Upload Video Formation (Admin only idealement)
router.post('/formation/video', upload.single('formation_video'), validateMagicBytes, (req, res) => {
    if (!req.file) {
        return res.status(400).json({ success: false, message: 'Aucun fichier fourni' });
    }
    res.json({
        success: true,
        message: 'Vidéo uploadée avec succès',
        fileUrl: `/uploads/videos/${req.file.filename}`,
        filename: req.file.filename
    });
});

module.exports = router;
