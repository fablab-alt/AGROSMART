/**
 * Utilitaire de logging sécurisé
 * AgroSmart - Système Agricole Intelligent
 * 
 * Ce module fournit des fonctions de logging qui:
 * - Ne loguent qu'en mode développement
 * - Masquent les données sensibles
 * - Utilisent des niveaux de log appropriés
 */

const config = require('./index');

// Patterns de données sensibles à masquer
const SENSITIVE_PATTERNS = [
  { regex: /password["\s]*[:=]["\s]*"[^"]+"/gi, replacement: 'password: "[MASKED]"' },
  { regex: /token["\s]*[:=]["\s]*"[^"]+"/gi, replacement: 'token: "[MASKED]"' },
  { regex: /secret["\s]*[:=]["\s]*"[^"]+"/gi, replacement: 'secret: "[MASKED]"' },
  { regex: /authorization["\s]*[:=]["\s]*"[^"]+"/gi, replacement: 'authorization: "[MASKED]"' },
  { regex: /Bearer\s+[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+/gi, replacement: 'Bearer [MASKED_JWT]' },
  { regex: /otp["\s]*[:=]["\s]*"?\d+"?/gi, replacement: 'otp: "[MASKED]"' },
];

/**
 * Masque les données sensibles dans une chaîne
 */
const maskSensitiveData = (data) => {
  if (typeof data !== 'string') {
    try {
      data = JSON.stringify(data, null, 2);
    } catch {
      data = String(data);
    }
  }

  let masked = data;
  for (const pattern of SENSITIVE_PATTERNS) {
    masked = masked.replace(pattern.regex, pattern.replacement);
  }
  return masked;
};

/**
 * Logger de développement - n'affiche qu'en mode dev
 */
const devLog = (...args) => {
  if (config.isDev) {
    const maskedArgs = args.map(arg => {
      if (typeof arg === 'string') {
        return maskSensitiveData(arg);
      }
      if (typeof arg === 'object' && arg !== null) {
        return maskSensitiveData(arg);
      }
      return arg;
    });
    console.log('[DEV]', ...maskedArgs);
  }
};

/**
 * Logger de debug - n'affiche qu'en mode dev avec préfixe DEBUG
 */
const debugLog = (context, ...args) => {
  if (config.isDev) {
    const maskedArgs = args.map(arg => {
      if (typeof arg === 'string') {
        return maskSensitiveData(arg);
      }
      if (typeof arg === 'object' && arg !== null) {
        return maskSensitiveData(arg);
      }
      return arg;
    });
    console.log(`[DEBUG:${context}]`, ...maskedArgs);
  }
};

/**
 * Logger d'info - affiche toujours mais masque les données sensibles
 */
const infoLog = (...args) => {
  const maskedArgs = args.map(arg => {
    if (typeof arg === 'string') {
      return maskSensitiveData(arg);
    }
    if (typeof arg === 'object' && arg !== null) {
      return maskSensitiveData(arg);
    }
    return arg;
  });
  console.log('[INFO]', ...maskedArgs);
};

/**
 * Logger d'avertissement - affiche toujours
 */
const warnLog = (...args) => {
  console.warn('[WARN]', ...args);
};

/**
 * Logger d'erreur - affiche toujours mais masque les données sensibles
 */
const errorLog = (context, error, additionalInfo = {}) => {
  const safeInfo = maskSensitiveData(additionalInfo);
  console.error(`[ERROR:${context}]`, error.message || error, safeInfo);
  
  // En dev, afficher la stack trace
  if (config.isDev && error.stack) {
    console.error('[STACK]', error.stack);
  }
};

/**
 * Logger de requête HTTP - masque les headers sensibles
 */
const requestLog = (req) => {
  if (!config.isDev) return;
  
  const safeHeaders = { ...req.headers };
  if (safeHeaders.authorization) safeHeaders.authorization = '[MASKED]';
  if (safeHeaders.cookie) safeHeaders.cookie = '[MASKED]';
  
  console.log('[REQUEST]', {
    method: req.method,
    url: req.originalUrl,
    ip: req.ip,
    userAgent: req.get('User-Agent')?.substring(0, 50),
    userId: req.user?.id || 'anonymous'
  });
};

module.exports = {
  devLog,
  debugLog,
  infoLog,
  warnLog,
  errorLog,
  requestLog,
  maskSensitiveData
};
