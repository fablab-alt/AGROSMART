/**
 * Centralized Error Codes for AgroSmart
 * Provides consistent error codes and messages across the application
 */

// Error code format: {CATEGORY}_{TYPE}_{NUMBER}
// Categories: AUTH, USER, PARCELLE, SENSOR, MARKET, DB, VALID, SYS

const ErrorCodes = {
  // ============================================
  // Authentication Errors (AUTH_)
  // ============================================
  AUTH_INVALID_CREDENTIALS: {
    code: 'AUTH_001',
    status: 401,
    message: 'Email ou mot de passe incorrect',
    messageEn: 'Invalid email or password'
  },
  AUTH_TOKEN_EXPIRED: {
    code: 'AUTH_002',
    status: 401,
    message: 'Session expirée, veuillez vous reconnecter',
    messageEn: 'Session expired, please login again'
  },
  AUTH_TOKEN_INVALID: {
    code: 'AUTH_003',
    status: 401,
    message: 'Token d\'authentification invalide',
    messageEn: 'Invalid authentication token'
  },
  AUTH_REFRESH_TOKEN_INVALID: {
    code: 'AUTH_004',
    status: 401,
    message: 'Token de rafraîchissement invalide ou expiré',
    messageEn: 'Invalid or expired refresh token'
  },
  AUTH_OTP_INVALID: {
    code: 'AUTH_005',
    status: 400,
    message: 'Code OTP invalide ou expiré',
    messageEn: 'Invalid or expired OTP code'
  },
  AUTH_OTP_MAX_ATTEMPTS: {
    code: 'AUTH_006',
    status: 429,
    message: 'Nombre maximum de tentatives OTP atteint',
    messageEn: 'Maximum OTP attempts reached'
  },
  AUTH_UNAUTHORIZED: {
    code: 'AUTH_007',
    status: 401,
    message: 'Non autorisé',
    messageEn: 'Unauthorized'
  },
  AUTH_FORBIDDEN: {
    code: 'AUTH_008',
    status: 403,
    message: 'Accès refusé',
    messageEn: 'Access denied'
  },
  AUTH_USER_SUSPENDED: {
    code: 'AUTH_009',
    status: 403,
    message: 'Compte suspendu',
    messageEn: 'Account suspended'
  },
  AUTH_PASSWORD_MISMATCH: {
    code: 'AUTH_010',
    status: 400,
    message: 'Les mots de passe ne correspondent pas',
    messageEn: 'Passwords do not match'
  },
  AUTH_PASSWORD_WEAK: {
    code: 'AUTH_011',
    status: 400,
    message: 'Mot de passe trop faible',
    messageEn: 'Password too weak'
  },
  AUTH_PASSWORD_REUSED: {
    code: 'AUTH_012',
    status: 400,
    message: 'Ce mot de passe a déjà été utilisé récemment',
    messageEn: 'This password was recently used'
  },

  // ============================================
  // User Errors (USER_)
  // ============================================
  USER_NOT_FOUND: {
    code: 'USER_001',
    status: 404,
    message: 'Utilisateur non trouvé',
    messageEn: 'User not found'
  },
  USER_ALREADY_EXISTS: {
    code: 'USER_002',
    status: 409,
    message: 'Un utilisateur avec cet email existe déjà',
    messageEn: 'A user with this email already exists'
  },
  USER_PHONE_EXISTS: {
    code: 'USER_003',
    status: 409,
    message: 'Ce numéro de téléphone est déjà utilisé',
    messageEn: 'This phone number is already in use'
  },
  USER_PROFILE_INCOMPLETE: {
    code: 'USER_004',
    status: 400,
    message: 'Profil utilisateur incomplet',
    messageEn: 'User profile incomplete'
  },
  USER_UPDATE_FAILED: {
    code: 'USER_005',
    status: 500,
    message: 'Échec de la mise à jour du profil',
    messageEn: 'Profile update failed'
  },

  // ============================================
  // Parcelle Errors (PARCELLE_)
  // ============================================
  PARCELLE_NOT_FOUND: {
    code: 'PARCELLE_001',
    status: 404,
    message: 'Parcelle non trouvée',
    messageEn: 'Plot not found'
  },
  PARCELLE_ACCESS_DENIED: {
    code: 'PARCELLE_002',
    status: 403,
    message: 'Accès à cette parcelle refusé',
    messageEn: 'Access to this plot denied'
  },
  PARCELLE_CREATION_FAILED: {
    code: 'PARCELLE_003',
    status: 500,
    message: 'Échec de la création de la parcelle',
    messageEn: 'Plot creation failed'
  },
  PARCELLE_INVALID_COORDINATES: {
    code: 'PARCELLE_004',
    status: 400,
    message: 'Coordonnées GPS invalides',
    messageEn: 'Invalid GPS coordinates'
  },

  // ============================================
  // Sensor/IoT Errors (SENSOR_)
  // ============================================
  SENSOR_NOT_FOUND: {
    code: 'SENSOR_001',
    status: 404,
    message: 'Capteur non trouvé',
    messageEn: 'Sensor not found'
  },
  SENSOR_OFFLINE: {
    code: 'SENSOR_002',
    status: 503,
    message: 'Capteur hors ligne',
    messageEn: 'Sensor offline'
  },
  SENSOR_DATA_INVALID: {
    code: 'SENSOR_003',
    status: 400,
    message: 'Données du capteur invalides',
    messageEn: 'Invalid sensor data'
  },
  SENSOR_BATTERY_LOW: {
    code: 'SENSOR_004',
    status: 200,
    message: 'Batterie du capteur faible',
    messageEn: 'Sensor battery low'
  },

  // ============================================
  // Marketplace Errors (MARKET_)
  // ============================================
  MARKET_PRODUCT_NOT_FOUND: {
    code: 'MARKET_001',
    status: 404,
    message: 'Produit non trouvé',
    messageEn: 'Product not found'
  },
  MARKET_INSUFFICIENT_STOCK: {
    code: 'MARKET_002',
    status: 400,
    message: 'Stock insuffisant',
    messageEn: 'Insufficient stock'
  },
  MARKET_ORDER_FAILED: {
    code: 'MARKET_003',
    status: 500,
    message: 'Échec de la commande',
    messageEn: 'Order failed'
  },
  MARKET_PAYMENT_FAILED: {
    code: 'MARKET_004',
    status: 402,
    message: 'Échec du paiement',
    messageEn: 'Payment failed'
  },
  MARKET_GROUP_PURCHASE_FULL: {
    code: 'MARKET_005',
    status: 400,
    message: 'Achat groupé complet',
    messageEn: 'Group purchase is full'
  },
  MARKET_GROUP_PURCHASE_EXPIRED: {
    code: 'MARKET_006',
    status: 400,
    message: 'Achat groupé expiré',
    messageEn: 'Group purchase has expired'
  },

  // ============================================
  // Database Errors (DB_)
  // ============================================
  DB_CONNECTION_ERROR: {
    code: 'DB_001',
    status: 503,
    message: 'Erreur de connexion à la base de données',
    messageEn: 'Database connection error'
  },
  DB_QUERY_FAILED: {
    code: 'DB_002',
    status: 500,
    message: 'Erreur lors de la requête',
    messageEn: 'Query failed'
  },
  DB_UNIQUE_VIOLATION: {
    code: 'DB_003',
    status: 409,
    message: 'Donnée déjà existante',
    messageEn: 'Data already exists'
  },
  DB_FOREIGN_KEY_VIOLATION: {
    code: 'DB_004',
    status: 400,
    message: 'Référence invalide',
    messageEn: 'Invalid reference'
  },
  DB_RECORD_NOT_FOUND: {
    code: 'DB_005',
    status: 404,
    message: 'Enregistrement non trouvé',
    messageEn: 'Record not found'
  },

  // ============================================
  // Validation Errors (VALID_)
  // ============================================
  VALID_REQUIRED_FIELD: {
    code: 'VALID_001',
    status: 400,
    message: 'Champ requis manquant',
    messageEn: 'Required field missing'
  },
  VALID_INVALID_FORMAT: {
    code: 'VALID_002',
    status: 400,
    message: 'Format invalide',
    messageEn: 'Invalid format'
  },
  VALID_INVALID_EMAIL: {
    code: 'VALID_003',
    status: 400,
    message: 'Email invalide',
    messageEn: 'Invalid email'
  },
  VALID_INVALID_PHONE: {
    code: 'VALID_004',
    status: 400,
    message: 'Numéro de téléphone invalide',
    messageEn: 'Invalid phone number'
  },
  VALID_VALUE_OUT_OF_RANGE: {
    code: 'VALID_005',
    status: 400,
    message: 'Valeur hors limite',
    messageEn: 'Value out of range'
  },
  VALID_INVALID_DATE: {
    code: 'VALID_006',
    status: 400,
    message: 'Date invalide',
    messageEn: 'Invalid date'
  },

  // ============================================
  // System Errors (SYS_)
  // ============================================
  SYS_INTERNAL_ERROR: {
    code: 'SYS_001',
    status: 500,
    message: 'Erreur interne du serveur',
    messageEn: 'Internal server error'
  },
  SYS_SERVICE_UNAVAILABLE: {
    code: 'SYS_002',
    status: 503,
    message: 'Service temporairement indisponible',
    messageEn: 'Service temporarily unavailable'
  },
  SYS_RATE_LIMIT_EXCEEDED: {
    code: 'SYS_003',
    status: 429,
    message: 'Trop de requêtes, veuillez réessayer plus tard',
    messageEn: 'Too many requests, please try again later'
  },
  SYS_MAINTENANCE: {
    code: 'SYS_004',
    status: 503,
    message: 'Système en maintenance',
    messageEn: 'System under maintenance'
  },
  SYS_FILE_UPLOAD_FAILED: {
    code: 'SYS_005',
    status: 500,
    message: 'Échec du téléchargement du fichier',
    messageEn: 'File upload failed'
  },
  SYS_FILE_TOO_LARGE: {
    code: 'SYS_006',
    status: 413,
    message: 'Fichier trop volumineux',
    messageEn: 'File too large'
  },
  SYS_INVALID_FILE_TYPE: {
    code: 'SYS_007',
    status: 400,
    message: 'Type de fichier non autorisé',
    messageEn: 'File type not allowed'
  },

  // ============================================
  // Weather/External API Errors (EXT_)
  // ============================================
  EXT_WEATHER_API_ERROR: {
    code: 'EXT_001',
    status: 502,
    message: 'Erreur du service météo',
    messageEn: 'Weather service error'
  },
  EXT_AI_SERVICE_ERROR: {
    code: 'EXT_002',
    status: 502,
    message: 'Erreur du service IA',
    messageEn: 'AI service error'
  },
  EXT_SMS_SEND_FAILED: {
    code: 'EXT_003',
    status: 502,
    message: 'Échec de l\'envoi du SMS',
    messageEn: 'SMS send failed'
  },
  EXT_EMAIL_SEND_FAILED: {
    code: 'EXT_004',
    status: 502,
    message: 'Échec de l\'envoi de l\'email',
    messageEn: 'Email send failed'
  }
};

/**
 * Create an API error response
 * @param {Object} errorDef - Error definition from ErrorCodes
 * @param {string} [details] - Additional details
 * @param {Object} [data] - Additional data
 * @returns {Object} Error response object
 */
function createError(errorDef, details = null, data = null) {
  const error = {
    success: false,
    error: {
      code: errorDef.code,
      message: errorDef.message,
      ...(details && { details }),
      ...(data && { data })
    }
  };
  error.status = errorDef.status;
  return error;
}

/**
 * Create an AppError with proper status and code
 */
class AppError extends Error {
  constructor(errorDef, details = null) {
    super(errorDef.message);
    this.name = 'AppError';
    this.code = errorDef.code;
    this.status = errorDef.status;
    this.details = details;
    Error.captureStackTrace(this, this.constructor);
  }

  toJSON() {
    return {
      success: false,
      error: {
        code: this.code,
        message: this.message,
        ...(this.details && { details: this.details })
      }
    };
  }
}

/**
 * Map Prisma errors to application errors
 * @param {Error} error - Prisma error
 * @returns {Object} Mapped error
 */
function mapPrismaError(error) {
  if (!error.code) {
    return ErrorCodes.DB_QUERY_FAILED;
  }

  switch (error.code) {
    case 'P2002':
      return ErrorCodes.DB_UNIQUE_VIOLATION;
    case 'P2003':
      return ErrorCodes.DB_FOREIGN_KEY_VIOLATION;
    case 'P2025':
      return ErrorCodes.DB_RECORD_NOT_FOUND;
    case 'P2024':
      return ErrorCodes.DB_CONNECTION_ERROR;
    default:
      return ErrorCodes.DB_QUERY_FAILED;
  }
}

/**
 * Get error message in specified language
 * @param {Object} errorDef - Error definition
 * @param {string} lang - Language code ('fr' or 'en')
 * @returns {string} Error message
 */
function getErrorMessage(errorDef, lang = 'fr') {
  return lang === 'en' ? (errorDef.messageEn || errorDef.message) : errorDef.message;
}

module.exports = {
  ErrorCodes,
  createError,
  AppError,
  mapPrismaError,
  getErrorMessage
};
