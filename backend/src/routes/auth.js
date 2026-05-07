/**
 * Routes d'authentification
 * AgroSmart - Système Agricole Intelligent
 */

const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { schemas, authenticate, verifyRefreshToken } = require('../middlewares');
const { 
  loginLimiter, 
  registerLimiter, 
  otpLimiter, 
  otpVerifyLimiter,
  passwordResetLimiter,
  uploadLimiter 
} = require('../middlewares/rateLimiter');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configuration multer
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadDir = 'uploads/profiles/';
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = file.mimetype.split('/')[1] || path.extname(file.originalname).substring(1);
        cb(null, 'profile-' + req.user.id + '-' + uniqueSuffix + '.' + ext);
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

/**
 * @route   POST /api/auth/register
 * @desc    Inscription d'un nouvel utilisateur
 * @access  Public
 * @rateLimit 3 créations par heure par IP
 */
router.post('/register', registerLimiter, schemas.register, authController.register);

/**
 * @route   POST /api/auth/login
 * @desc    Connexion (première étape - envoi OTP)
 * @access  Public
 * @rateLimit 5 tentatives par 15 minutes par IP+email
 */
router.post('/login', loginLimiter, schemas.login, authController.login);

/**
 * @route   POST /api/auth/verify-otp
 * @desc    Vérification du code OTP
 * @access  Public
 * @rateLimit 10 tentatives par 5 minutes
 */
router.post('/verify-otp', otpVerifyLimiter, schemas.verifyOtp, authController.verifyOtp);

/**
 * @route   POST /api/auth/refresh
 * @desc    Rafraîchir le token d'accès
 * @access  Public (avec refresh token valide)
 */
router.post('/refresh', verifyRefreshToken, authController.refreshToken);

/**
 * @route   POST /api/auth/logout
 * @desc    Déconnexion (révocation du refresh token)
 * @access  Private
 */
router.post('/logout', authenticate, authController.logout);

/**
 * @route   POST /api/auth/forgot-password
 * @desc    Demande de réinitialisation du mot de passe
 * @access  Public
 * @rateLimit 3 demandes par heure par email
 */
router.post('/forgot-password', passwordResetLimiter, authController.forgotPassword);

/**
 * @route   POST /api/auth/reset-password
 * @desc    Réinitialisation du mot de passe
 * @access  Public (avec token valide)
 * @rateLimit 3 demandes par heure
 */
router.post('/reset-password', passwordResetLimiter, authController.resetPassword);

/**
 * @route   POST /api/auth/resend-otp
 * @desc    Renvoyer le code OTP
 * @access  Public
 * @rateLimit 5 demandes par 10 minutes
 */
router.post('/resend-otp', otpLimiter, authController.resendOtp);

/**
 * @route   POST /api/auth/otp/verify
 * @desc    Vérifier le code OTP (alias de verify-otp)
 * @access  Public
 * @rateLimit 10 tentatives par 5 minutes
 */
router.post('/otp/verify', otpVerifyLimiter, schemas.verifyOtp, authController.verifyOtp);

/**
 * @route   GET /api/auth/me
 * @desc    Obtenir le profil de l'utilisateur connecté
 * @access  Private
 */
router.get('/me', authenticate, authController.getMe);

/**
 * @route   PUT /api/auth/me
 * @desc    Mettre à jour le profil
 * @access  Private
 * @rateLimit 20 uploads par heure
 */
router.put('/me', authenticate, uploadLimiter, upload.single('photo'), authController.updateMe);

/**
 * @route   PUT /api/auth/change-password
 * @desc    Changer le mot de passe
 * @access  Private
 */
router.put('/change-password', authenticate, authController.changePassword);

module.exports = router;
