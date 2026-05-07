/**
 * Rate Limiting avancé par endpoint
 * AgroSmart - Système Agricole Intelligent
 * 
 * Ce module fournit des limiteurs de débit spécifiques:
 * - Login: Protection contre les attaques brute-force
 * - Register: Limite les créations de comptes
 * - OTP: Protection contre le spam de codes
 * - API générale: Limite globale par IP
 * - Upload: Limite les téléchargements de fichiers
 * 
 * @module middlewares/rateLimiter
 */

const rateLimit = require('express-rate-limit');
const { ipKeyGenerator } = require('express-rate-limit');
const config = require('../config');
const logger = require('../utils/logger');

/**
 * Mode mémoire uniquement pour le rate limiting.
 * Store externe volontairement retiré du runtime backend.
 * @param {string} prefix - Préfixe pour les clés
 * @returns {undefined}
 */
const createLimiterStore = (prefix) => {
  logger.debug(`Rate limiter '${prefix}' uses in-memory store`);
  return undefined;
};

/**
 * Handler personnalisé pour les erreurs de rate limit
 * @param {Request} req 
 * @param {Response} res 
 * @param {NextFunction} next 
 * @param {Object} options 
 */
const rateLimitHandler = (req, res, next, options) => {
  logger.warn(`Rate limit exceeded`, {
    ip: req.ip,
    path: req.path,
    method: req.method,
    userAgent: req.get('User-Agent'),
    limitType: options.limitType || 'general'
  });
  
  res.status(429).json({
    success: false,
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: options.message || 'Trop de requêtes, veuillez réessayer plus tard.',
      retryAfter: Math.ceil(options.windowMs / 1000)
    }
  });
};

const getClientIp = (req) => ipKeyGenerator(req);

// Options de validation communes pour désactiver les avertissements IPv6
const commonValidateOptions = { xForwardedForHeader: false, ip: false, keyGeneratorIpFallback: false };

/**
 * Rate limiter pour la connexion (Login)
 * - 100 tentatives par 15 minutes par IP en dev
 * - 10 tentatives en prod (plus souple pour UX)
 * - Bloque les attaques brute-force
 */
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.NODE_ENV === 'production' ? 10 : 100, // 10 en prod, 100 en dev
  message: 'Trop de tentatives de connexion. Réessayez dans 15 minutes.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createLimiterStore('login'),
  validate: commonValidateOptions,
  keyGenerator: (req) => {
    // Utiliser seulement l'IP pour éviter le blocage par email
    const ip = getClientIp(req);
    return `${ip}`;
  },
  skip: (req) => {
    // Ne pas limiter en mode test ou dev local
    return config.isTest || process.env.NODE_ENV === 'development';
  },
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'login' });
  }
});

/**
 * Rate limiter pour l'inscription (Register)
 * - 50 créations de compte par heure par IP (dev mode)
 * - Prévient le spam de comptes
 */
const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 heure
  max: process.env.NODE_ENV === 'production' ? 5 : 50, // 5 en prod, 50 en dev
  message: 'Trop de créations de compte. Réessayez dans 1 heure.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createLimiterStore('register'),
  validate: commonValidateOptions,
  keyGenerator: (req) => getClientIp(req),
  skip: (req) => config.isTest || process.env.NODE_ENV === 'development',
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'register' });
  }
});

/**
 * Rate limiter pour les OTP
 * - 20 demandes par 10 minutes par téléphone en dev
 * - Prévient le spam SMS coûteux
 */
const otpLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  max: process.env.NODE_ENV === 'production' ? 5 : 20, // 5 en prod, 20 en dev
  message: 'Trop de demandes de code OTP. Réessayez dans 10 minutes.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createLimiterStore('otp'),
  validate: commonValidateOptions,
  keyGenerator: (req) => {
    const phone = req.body?.telephone || req.params?.telephone || 'unknown';
    const ip = getClientIp(req);
    return `${ip}:${phone}`;
  },
  skip: (req) => config.isTest || process.env.NODE_ENV === 'development',
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'otp' });
  }
});

/**
 * Rate limiter pour la vérification OTP
 * - 30 vérifications par 5 minutes en dev
 * - Empêche le brute-force des codes
 */
const otpVerifyLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: process.env.NODE_ENV === 'production' ? 10 : 30, // 10 en prod, 30 en dev
  message: 'Trop de tentatives de vérification. Réessayez dans 5 minutes.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createLimiterStore('otp-verify'),
  validate: commonValidateOptions,
  keyGenerator: (req) => {
    const phone = req.body?.telephone || 'unknown';
    const ip = getClientIp(req);
    return `${ip}:${phone}`;
  },
  skip: (req) => config.isTest || process.env.NODE_ENV === 'development',
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'otp-verify' });
  }
});

/**
 * Rate limiter pour les uploads
 * - 20 uploads par heure par utilisateur
 * - Protège le stockage et la bande passante
 */
const uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 heure
  max: 20, // 20 uploads max
  message: 'Trop de fichiers téléchargés. Réessayez dans 1 heure.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createLimiterStore('upload'),
  validate: commonValidateOptions,
  keyGenerator: (req) => {
    const userId = req.user?.id || getClientIp(req);
    return `upload:${userId}`;
  },
  skip: (req) => config.isTest,
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'upload' });
  }
});

/**
 * Rate limiter pour le diagnostic IA
 * - 10 diagnostics par heure par utilisateur
 * - Protège le service IA des surcharges
 */
const diagnosticLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 heure
  max: 10, // 10 diagnostics max
  message: 'Trop de diagnostics demandés. Réessayez dans 1 heure.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createLimiterStore('diagnostic'),
  validate: commonValidateOptions,
  keyGenerator: (req) => {
    const userId = req.user?.id || getClientIp(req);
    return `diag:${userId}`;
  },
  skip: (req) => config.isTest,
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'diagnostic' });
  }
});

/**
 * Rate limiter pour les requêtes API générales
 * - 100 requêtes par minute par IP
 * - Protection DDoS basique
 */
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100, // 100 requêtes max
  message: 'Trop de requêtes. Veuillez patienter.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createLimiterStore('api'),
  validate: commonValidateOptions,
  keyGenerator: (req) => getClientIp(req),
  skip: (req) => config.isTest,
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'api' });
  }
});

/**
 * Rate limiter strict pour les endpoints sensibles
 * - 30 requêtes par minute
 * - Pour les endpoints critiques
 */
const strictLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 30, // 30 requêtes max
  message: 'Limite de requêtes atteinte pour cette ressource.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createLimiterStore('strict'),
  validate: commonValidateOptions,
  keyGenerator: (req) => {
    const userId = req.user?.id || getClientIp(req);
    return `strict:${userId}`;
  },
  skip: (req) => config.isTest,
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'strict' });
  }
});

/**
 * Rate limiter pour le mot de passe oublié
 * - 3 demandes par heure par email
 */
const passwordResetLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 heure
  max: 3, // 3 demandes max
  message: 'Trop de demandes de réinitialisation. Réessayez dans 1 heure.',
  standardHeaders: true,
  legacyHeaders: false,
  store: createLimiterStore('pwd-reset'),
  validate: commonValidateOptions,
  keyGenerator: (req) => {
    const email = req.body?.email || 'unknown';
    const ip = getClientIp(req);
    return `${ip}:${email}`;
  },
  skip: (req) => config.isTest,
  handler: (req, res, next, options) => {
    rateLimitHandler(req, res, next, { ...options, limitType: 'password-reset' });
  }
});

module.exports = {
  loginLimiter,
  registerLimiter,
  otpLimiter,
  otpVerifyLimiter,
  uploadLimiter,
  diagnosticLimiter,
  apiLimiter,
  strictLimiter,
  passwordResetLimiter
};
