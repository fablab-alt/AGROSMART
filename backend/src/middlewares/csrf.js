/**
 * Protection CSRF via le pattern Double-Submit Cookie.
 *
 * Fonctionnement :
 *  1. GET /api/v1/csrf-token  → génère un token, le pose en cookie + le retourne dans le JSON.
 *  2. Toute mutation (POST/PUT/PATCH/DELETE) doit envoyer ce token dans le header X-CSRF-Token.
 *  3. Le middleware compare le header au cookie ; s'ils correspondent, la requête est légitime.
 *
 * Pas de stockage serveur : le cookie SameSite=Strict + HTTPS = protection suffisante
 * contre les CSRF cross-origin (le navigateur refuse d'envoyer le cookie d'un autre domaine).
 *
 * Exemptions :
 *  - GET, HEAD, OPTIONS (idempotents)
 *  - Routes d'authentification initiale (/auth/login, /auth/register, /auth/refresh)
 *    car le client n'a pas encore de token CSRF avant le premier login.
 *  - /health, /readiness
 */

const crypto = require('crypto');
const logger = require('../utils/logger');

const CSRF_COOKIE = 'csrf_token';
const CSRF_HEADER = 'x-csrf-token';
const SAFE_METHODS = new Set(['GET', 'HEAD', 'OPTIONS']);
const EXEMPT_PATHS = new Set([
  '/api/v1/auth/login',
  '/api/v1/auth/register',
  '/api/v1/auth/refresh',
  '/api/v1/auth/forgot-password',
  '/api/v1/auth/reset-password',
  '/api/v1/auth/verify-otp',
  '/health',
  '/readiness',
]);

/**
 * Génère un token CSRF sécurisé (32 octets = 64 hex chars).
 */
const generateToken = () => crypto.randomBytes(32).toString('hex');

/**
 * Route handler : GET /api/v1/csrf-token
 * Retourne (ou renouvelle) le token CSRF dans un cookie + corps JSON.
 */
const csrfTokenHandler = (req, res) => {
  let token = req.cookies?.[CSRF_COOKIE];
  if (!token || token.length !== 64) {
    token = generateToken();
  }

  res.cookie(CSRF_COOKIE, token, {
    httpOnly: false, // Lisible par JS pour extraction côté client
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    maxAge: 24 * 60 * 60 * 1000, // 24 h
    path: '/',
  });

  return res.json({ csrfToken: token });
};

/**
 * Middleware Express : valide X-CSRF-Token sur les mutations.
 */
const csrfProtection = (req, res, next) => {
  if (SAFE_METHODS.has(req.method)) return next();
  if (EXEMPT_PATHS.has(req.path)) return next();

  const cookieToken = req.cookies?.[CSRF_COOKIE];
  const headerToken = req.headers[CSRF_HEADER];

  if (!cookieToken || !headerToken) {
    logger.warn('CSRF: token manquant', { path: req.path, method: req.method, ip: req.ip });
    return res.status(403).json({
      success: false,
      error: { code: 'CSRF_TOKEN_MISSING', message: 'Token CSRF manquant.' }
    });
  }

  // Comparaison en temps constant pour éviter les timing attacks
  if (!crypto.timingSafeEqual(Buffer.from(cookieToken), Buffer.from(headerToken))) {
    logger.warn('CSRF: token invalide', { path: req.path, method: req.method, ip: req.ip });
    return res.status(403).json({
      success: false,
      error: { code: 'CSRF_TOKEN_INVALID', message: 'Token CSRF invalide.' }
    });
  }

  next();
};

module.exports = { csrfProtection, csrfTokenHandler };
