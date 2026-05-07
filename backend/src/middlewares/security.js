/**
 * Middleware de sécurité avancée
 * AgroSmart - Système Agricole Intelligent
 * 
 * Ce module fournit des fonctionnalités de sécurité supplémentaires:
 * - Protection XSS avancée
 * - Validation des entrées
 * - Protection contre les injections SQL
 * - Rate limiting par utilisateur
 * - Détection des attaques brute-force
 * 
 * @module middlewares/security
 */

const logger = require('../utils/logger');

/**
 * Cache pour le suivi des tentatives de connexion
 * Format: { ip: { count: number, lastAttempt: Date, blocked: boolean } }
 */
const loginAttempts = new Map();

// Nettoyage périodique des tentatives expirées (évite les fuites mémoire)
setInterval(() => {
  const now = Date.now();
  for (const [key, data] of loginAttempts.entries()) {
    if (now - data.lastAttempt > BRUTE_FORCE_CONFIG.windowMs) {
      loginAttempts.delete(key);
    }
  }
}, 5 * 60 * 1000); // Nettoyage toutes les 5 minutes

/**
 * Configuration par défaut de la protection brute-force
 */
const BRUTE_FORCE_CONFIG = {
  maxAttempts: 5,          // Nombre max de tentatives
  windowMs: 15 * 60 * 1000, // Fenêtre de 15 minutes
  blockDuration: 30 * 60 * 1000, // Blocage de 30 minutes
};

/**
 * Nettoie les entrées utilisateur pour prévenir les attaques XSS
 * 
 * @param {string} input - Chaîne à nettoyer
 * @returns {string} Chaîne nettoyée
 */
const sanitizeInput = (input) => {
  if (typeof input !== 'string') return input;
  
  return input
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '') // Supprime les balises script
    .replace(/javascript:/gi, '') // Supprime les URLs javascript
    .replace(/on\w+\s*=/gi, '') // Supprime les event handlers
    .replace(/data:text\/html/gi, '') // Supprime les data URIs HTML dangereux
    .trim();
};

/**
 * Middleware pour nettoyer toutes les entrées de la requête
 * Protège contre les attaques XSS et les injections
 * 
 * @param {express.Request} req
 * @param {express.Response} res
 * @param {express.NextFunction} next
 */
const sanitizeMiddleware = (req, res, next) => {
  // Nettoyer le body
  if (req.body && typeof req.body === 'object') {
    req.body = sanitizeObject(req.body);
  }

  // Nettoyer les query params
  if (req.query && typeof req.query === 'object') {
    req.query = sanitizeObject(req.query);
  }

  // Nettoyer les params
  if (req.params && typeof req.params === 'object') {
    req.params = sanitizeObject(req.params);
  }

  next();
};

/**
 * Nettoie récursivement un objet
 * 
 * @param {Object} obj - Objet à nettoyer
 * @returns {Object} Objet nettoyé
 */
const sanitizeObject = (obj) => {
  const cleaned = {};
  
  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === 'string') {
      cleaned[key] = sanitizeInput(value);
    } else if (Array.isArray(value)) {
      cleaned[key] = value.map(item => 
        typeof item === 'string' ? sanitizeInput(item) : 
        typeof item === 'object' ? sanitizeObject(item) : item
      );
    } else if (value && typeof value === 'object') {
      cleaned[key] = sanitizeObject(value);
    } else {
      cleaned[key] = value;
    }
  }
  
  return cleaned;
};

/**
 * Middleware de protection contre les attaques brute-force
 * Limite les tentatives de connexion par IP
 * 
 * @param {Object} options - Options de configuration
 * @returns {Function} Middleware Express
 */
const bruteForceProtection = (options = {}) => {
  const config = { ...BRUTE_FORCE_CONFIG, ...options };

  return (req, res, next) => {
    const ip = req.ip || req.connection.remoteAddress;
    const now = Date.now();

    // Nettoyer les anciennes entrées
    for (const [key, data] of loginAttempts.entries()) {
      if (now - data.lastAttempt > config.windowMs) {
        loginAttempts.delete(key);
      }
    }

    // Vérifier si l'IP est bloquée
    const attemptData = loginAttempts.get(ip);
    
    if (attemptData) {
      // Vérifier si le blocage est toujours actif
      if (attemptData.blocked && (now - attemptData.blockedAt < config.blockDuration)) {
        const remainingTime = Math.ceil((config.blockDuration - (now - attemptData.blockedAt)) / 60000);
        
        logger.warn(`Brute-force: IP ${ip} bloquée - ${remainingTime} minutes restantes`);
        
        return res.status(429).json({
          success: false,
          message: `Trop de tentatives. Réessayez dans ${remainingTime} minutes.`,
          code: 'BRUTE_FORCE_BLOCKED',
          retryAfter: remainingTime * 60
        });
      }

      // Si le blocage a expiré, réinitialiser
      if (attemptData.blocked && (now - attemptData.blockedAt >= config.blockDuration)) {
        loginAttempts.delete(ip);
      }
    }

    // Attacher les fonctions de suivi à la requête
    req.trackLoginAttempt = (success) => {
      if (success) {
        // Réinitialiser en cas de succès
        loginAttempts.delete(ip);
      } else {
        // Incrémenter le compteur en cas d'échec
        const current = loginAttempts.get(ip) || { count: 0, lastAttempt: now };
        current.count += 1;
        current.lastAttempt = now;

        if (current.count >= config.maxAttempts) {
          current.blocked = true;
          current.blockedAt = now;
          logger.warn(`Brute-force: IP ${ip} bloquée après ${current.count} tentatives`);
        }

        loginAttempts.set(ip, current);
      }
    };

    next();
  };
};

/**
 * Middleware pour ajouter des headers de sécurité supplémentaires
 * Complète helmet avec des protections additionnelles
 * 
 * @param {express.Request} req
 * @param {express.Response} res
 * @param {express.NextFunction} next
 */
const securityHeaders = (req, res, next) => {
  // Empêcher le caching des données sensibles
  if (req.path.includes('/auth') || req.path.includes('/user')) {
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
  }

  // Permissions Policy (remplace Feature-Policy)
  res.setHeader('Permissions-Policy', 
    'geolocation=(self), microphone=(), camera=(), payment=()'
  );

  // Protection supplémentaire contre le clickjacking
  res.setHeader('X-Frame-Options', 'DENY');

  // DNS Prefetch Control
  res.setHeader('X-DNS-Prefetch-Control', 'off');

  // Download Options (IE)
  res.setHeader('X-Download-Options', 'noopen');

  // Permitted Cross-Domain Policies
  res.setHeader('X-Permitted-Cross-Domain-Policies', 'none');

  next();
};

/**
 * Middleware pour valider les types de contenu
 * Rejette les requêtes avec des content-types invalides
 * 
 * @param {Array<string>} allowedTypes - Types de contenu autorisés
 * @returns {Function} Middleware Express
 */
const validateContentType = (allowedTypes = ['application/json', 'multipart/form-data']) => {
  return (req, res, next) => {
    // Ignorer les requêtes GET, HEAD, OPTIONS
    if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
      return next();
    }

    const contentType = req.headers['content-type'];
    
    // Si pas de content-type et pas de body, autoriser
    if (!contentType && (!req.body || Object.keys(req.body).length === 0)) {
      return next();
    }

    // Vérifier si le content-type est autorisé
    const isValid = allowedTypes.some(type => 
      contentType && contentType.toLowerCase().includes(type.toLowerCase())
    );

    if (!isValid) {
      logger.warn(`Content-Type invalide: ${contentType} de ${req.ip}`);
      return res.status(415).json({
        success: false,
        message: 'Type de contenu non supporté',
        code: 'UNSUPPORTED_MEDIA_TYPE'
      });
    }

    next();
  };
};

/**
 * Middleware pour détecter et bloquer les requêtes suspectes
 * Recherche des patterns d'attaque communs
 * 
 * @param {express.Request} req
 * @param {express.Response} res
 * @param {express.NextFunction} next
 */
const detectSuspiciousActivity = (req, res, next) => {
  // Patterns pour détecter les attaques (sans & qui est légitime dans les query strings)
  const suspiciousPatterns = [
    /(\.\.\/)/, // Path traversal
    /(union\s+select)/i, // SQL Injection
    /(<script>)/i, // XSS basique
    /(javascript:)/i, // JavaScript injection
    /(;\s*\w+\s*=)/, // Command injection avec point-virgule suivi de commande
    /(\|\|)/, // OR logique shell (double pipe)
    /(\$\()/, // Command substitution
  ];

  // Patterns plus stricts pour le body (pas les URLs)
  const bodyPatterns = [
    ...suspiciousPatterns,
    /(;\s*rm\s+-rf)/i, // rm -rf command
    /(;\s*cat\s+)/i, // cat command
    /(;\s*wget\s+)/i, // wget command
    /(;\s*curl\s+)/i, // curl command
  ];

  /**
   * Vérifie si une chaîne contient des caractères de contrôle dangereux
   * @param {string} str - Chaîne à vérifier
   * @returns {boolean}
   */
  const hasControlCharacters = (str) => {
    if (typeof str !== 'string') return false;
    // Détecte les null bytes et autres caractères de contrôle
    for (let i = 0; i < str.length; i++) {
      const code = str.charCodeAt(i);
      // Caractères de contrôle: 0x00-0x08, 0x0B, 0x0C, 0x0E-0x1F
      if ((code >= 0 && code <= 8) || code === 11 || code === 12 || (code >= 14 && code <= 31)) {
        return true;
      }
    }
    return false;
  };

  const checkValue = (value, useBodyPatterns = false) => {
    if (typeof value !== 'string') return false;
    if (hasControlCharacters(value)) return true;
    const patterns = useBodyPatterns ? bodyPatterns : suspiciousPatterns;
    return patterns.some(pattern => pattern.test(value));
  };

  const checkObject = (obj) => {
    for (const value of Object.values(obj)) {
      if (typeof value === 'string' && checkValue(value, true)) {
        return true;
      }
      if (typeof value === 'object' && value !== null) {
        if (checkObject(value)) return true;
      }
    }
    return false;
  };

  // Vérifier uniquement le path (pas la query string complète)
  const urlPath = req.path || req.url.split('?')[0];
  if (checkValue(urlPath)) {
    logger.warn(`Chemin suspect détecté: ${urlPath} de ${req.ip}`);
    return res.status(400).json({
      success: false,
      message: 'Requête invalide',
      code: 'SUSPICIOUS_REQUEST'
    });
  }

  // Vérifier les valeurs individuelles des query params (pas le & séparateur)
  if (req.query && checkObject(req.query)) {
    logger.warn(`Query params suspects détectés de ${req.ip}`);
    return res.status(400).json({
      success: false,
      message: 'Requête invalide',
      code: 'SUSPICIOUS_REQUEST'
    });
  }

  // Vérifier le body
  if (req.body && checkObject(req.body)) {
    logger.warn(`Payload suspect détecté de ${req.ip}`);
    return res.status(400).json({
      success: false,
      message: 'Données invalides',
      code: 'SUSPICIOUS_PAYLOAD'
    });
  }

  next();
};

/**
 * Middleware combiné pour appliquer toutes les protections
 * Utilisation recommandée: app.use(securityMiddleware())
 * 
 * @param {Object} options - Options de configuration
 * @returns {Array<Function>} Tableau de middlewares
 */
const securityMiddleware = (options = {}) => {
  return [
    securityHeaders,
    sanitizeMiddleware,
    detectSuspiciousActivity,
    validateContentType(options.allowedContentTypes),
  ];
};

module.exports = {
  sanitizeInput,
  sanitizeMiddleware,
  sanitizeObject,
  bruteForceProtection,
  securityHeaders,
  validateContentType,
  detectSuspiciousActivity,
  securityMiddleware,
};
