const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { authenticate } = require('../middlewares/auth');

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

// Filtres fichiers
const fileFilter = (req, file, cb) => {
    if (file.fieldname === 'formation_video') {
        if (!file.originalname.match(/\.(mp4|avi|mov)$/)) {
            return cb(new Error('Seules les vidéos sont autorisées!'), false);
        }
    } else if (file.fieldname === 'diagnostic_image' || file.fieldname === 'chat_image') {
        if (!file.originalname.match(/\.(jpg|jpeg|png)$/)) {
            return cb(new Error('Seules les images sont autorisées!'), false);
        }
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
router.post('/diagnostic', upload.single('diagnostic_image'), (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'Aucun fichier fourni' });
        }
        res.json({
            success: true,
            message: 'Image uploadée avec succès',
            fileUrl: `/uploads/diagnostics/${req.file.filename}`,
            filename: req.file.filename
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// Route Upload Video Formation (Admin only idealement)
router.post('/formation/video', upload.single('formation_video'), (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'Aucun fichier fourni' });
        }
        res.json({
            success: true,
            message: 'Vidéo uploadée avec succès',
            fileUrl: `/uploads/videos/${req.file.filename}`,
            filename: req.file.filename
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

module.exports = router;
