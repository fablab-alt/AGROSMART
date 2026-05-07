/**
 * Configuration du logger Winston amélioré
 * AgroSmart - Système Agricole Intelligent
 * 
 * Features:
 * - Rotation quotidienne automatique des fichiers de logs
 * - Niveaux de log par environnement
 * - Logs structurés JSON en production
 * - Logs colorés en développement
 * - Méthodes spécialisées (audit, iot, perf, security)
 */

const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');
const path = require('path');
const config = require('../config');

// Niveaux de log personnalisés avec couleurs
const customLevels = {
  levels: {
    error: 0,
    warn: 1,
    security: 2,
    info: 3,
    http: 4,
    debug: 5,
  },
  colors: {
    error: 'red',
    warn: 'yellow',
    security: 'magenta',
    info: 'green',
    http: 'cyan',
    debug: 'gray',
  }
};

// Ajouter les couleurs personnalisées
winston.addColors(customLevels.colors);

// Répertoire des logs
const logDir = process.env.LOG_DIR || path.join(process.cwd(), 'logs');

// Format personnalisé pour les logs
const customFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ level, message, timestamp, stack, ...meta }) => {
    let log = `${timestamp} [${level.toUpperCase()}]: ${message}`;
    
    // Ajouter les métadonnées si présentes
    if (Object.keys(meta).length > 0) {
      log += ` ${JSON.stringify(meta)}`;
    }
    
    // Ajouter la stack trace si présente
    if (stack) {
      log += `\n${stack}`;
    }
    
    return log;
  })
);

// Format JSON pour la production
const jsonFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
  winston.format.errors({ stack: true }),
  winston.format.json()
);

// Configuration des transports
const transports = [];

// Console (toujours actif en dev)
if (!config.isProd) {
  transports.push(
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize({ all: true }),
        customFormat
      )
    })
  );
} else {
  // Console minimaliste en prod (pour Docker logs)
  transports.push(
    new winston.transports.Console({
      format: jsonFormat,
      level: 'info'
    })
  );
}

// Rotation quotidienne des logs en production
if (config.isProd || config.logs.file) {
  // Logs combinés (tous les niveaux)
  transports.push(
    new DailyRotateFile({
      dirname: logDir,
      filename: 'agrismart-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      zippedArchive: true,
      maxSize: '20m',
      maxFiles: '30d', // Garder 30 jours
      format: jsonFormat
    })
  );
  
  // Logs d'erreurs séparés
  transports.push(
    new DailyRotateFile({
      dirname: logDir,
      filename: 'error-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      zippedArchive: true,
      maxSize: '20m',
      maxFiles: '30d',
      level: 'error',
      format: jsonFormat
    })
  );

  // Logs de sécurité (login, brute-force, etc.)
  transports.push(
    new DailyRotateFile({
      dirname: logDir,
      filename: 'security-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      zippedArchive: true,
      maxSize: '20m',
      maxFiles: '90d', // Garder 90 jours pour les audits
      level: 'security',
      format: jsonFormat
    })
  );

  // Logs d'audit (actions utilisateur)
  transports.push(
    new DailyRotateFile({
      dirname: logDir,
      filename: 'audit-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      zippedArchive: true,
      maxSize: '20m',
      maxFiles: '365d', // Garder 1 an pour conformité
      format: jsonFormat
    })
  );
}

// Déterminer le niveau de log selon l'environnement
const getLogLevel = () => {
  if (config.isTest) return 'error'; // Moins verbeux en test
  if (config.isProd) return config.logs?.level || 'info';
  return 'debug';
};

// Création du logger
const logger = winston.createLogger({
  levels: customLevels.levels,
  level: getLogLevel(),
  format: customFormat,
  transports,
  exitOnError: false,
  // Gérer les exceptions non attrapées
  exceptionHandlers: config.isProd ? [
    new DailyRotateFile({
      dirname: logDir,
      filename: 'exceptions-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      zippedArchive: true,
      maxFiles: '30d'
    })
  ] : [],
  // Gérer les rejections de promesses
  rejectionHandlers: config.isProd ? [
    new DailyRotateFile({
      dirname: logDir,
      filename: 'rejections-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      zippedArchive: true,
      maxFiles: '30d'
    })
  ] : []
});

// ============================
// Méthodes spécialisées
// ============================

/**
 * Log d'audit pour les actions utilisateur
 * @param {string} action - Action effectuée
 * @param {Object} data - Données de l'action
 */
logger.audit = (action, data = {}) => {
  logger.info(`[AUDIT] ${action}`, { 
    audit: true, 
    action,
    timestamp: new Date().toISOString(),
    ...data 
  });
};

/**
 * Log de sécurité pour les événements sensibles
 * @param {string} event - Événement de sécurité
 * @param {Object} data - Données de l'événement
 */
logger.security = (event, data = {}) => {
  logger.log('security', `[SECURITY] ${event}`, {
    security: true,
    event,
    timestamp: new Date().toISOString(),
    ...data
  });
};

/**
 * Log IoT pour les données des capteurs
 * @param {string} event - Événement IoT
 * @param {Object} data - Données de l'événement
 */
logger.iot = (event, data = {}) => {
  logger.debug(`[IoT] ${event}`, { 
    iot: true, 
    event,
    ...data 
  });
};

/**
 * Log de performance pour le monitoring
 * @param {string} operation - Opération mesurée
 * @param {number} duration - Durée en ms
 * @param {Object} extra - Données supplémentaires
 */
logger.perf = (operation, duration, extra = {}) => {
  const level = duration > 1000 ? 'warn' : 'debug';
  logger.log(level, `[PERF] ${operation}`, { 
    performance: true, 
    operation,
    duration: `${duration}ms`,
    slow: duration > 1000,
    ...extra
  });
};

/**
 * Log HTTP pour les requêtes
 * @param {Object} req - Requête Express
 * @param {Object} res - Réponse Express
 * @param {number} duration - Durée en ms
 */
logger.http = (req, res, duration) => {
  const { method, originalUrl, ip } = req;
  const { statusCode } = res;
  
  const level = statusCode >= 400 ? 'warn' : 'http';
  logger.log(level, `${method} ${originalUrl}`, {
    http: true,
    method,
    url: originalUrl,
    status: statusCode,
    duration: `${duration}ms`,
    ip,
    userAgent: req.get('User-Agent')
  });
};

/**
 * Log d'erreur API structuré
 * @param {Error} error - Erreur
 * @param {Object} req - Requête Express
 */
logger.apiError = (error, req = {}) => {
  logger.error(`API Error: ${error.message}`, {
    error: true,
    message: error.message,
    stack: error.stack,
    code: error.code,
    path: req.originalUrl,
    method: req.method,
    ip: req.ip,
    userId: req.user?.id
  });
};

module.exports = logger;
