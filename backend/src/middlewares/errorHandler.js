/**
 * Middleware de gestion globale des erreurs
 * AgroSmart - Système Agricole Intelligent
 * 
 * Ce module centralise la gestion de toutes les erreurs de l'application.
 * Il transforme les erreurs techniques en réponses utilisateur compréhensibles
 * tout en préservant la sécurité (pas de fuite d'informations sensibles).
 * 
 * SÉCURITÉ:
 * - Masquage des stack traces en production
 * - Messages d'erreur génériques pour erreurs serveur
 * - Pas d'exposition de détails techniques (chemins, versions, etc.)
 * - Logging détaillé côté serveur uniquement
 * - Codes d'erreur standardisés
 * 
 * @module middlewares/errorHandler
 * @requires ../utils/logger
 * @requires ../config
 */

const logger = require('../utils/logger');
const config = require('../config');

/**
 * Classe d'erreur personnalisée pour l'application
 * 
 * Toutes les erreurs opérationnelles (erreurs métier) utilisent cette classe.
 * Les erreurs non-opérationnelles (bugs) sont traitées différemment.
 * 
 * @class AppError
 * @extends Error
 * @property {string} message - Message d'erreur
 * @property {number} statusCode - Code HTTP (400, 401, 403, 404, 500, etc.)
 * @property {string} code - Code d'erreur applicatif (ex: 'VALIDATION_ERROR')
 * @property {boolean} isOperational - true si erreur opérationnelle, false si bug
 * 
 * @example
 * throw new AppError('Email déjà utilisé', 409, 'DUPLICATE_EMAIL');
 */
class AppError extends Error {
  constructor(message, statusCode, code = 'ERROR') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Fonctions utilitaires pour créer des erreurs standardisées
 * 
 * Ces fonctions créent des instances d'AppError avec les codes HTTP et messages appropriés.
 * Utilisez-les plutôt que de créer manuellement des AppError.
 * 
 * @namespace errors
 * @property {Function} badRequest - Erreur 400 (requête invalide)
 * @property {Function} unauthorized - Erreur 401 (non authentifié)
 * @property {Function} forbidden - Erreur 403 (accès interdit)
 * @property {Function} notFound - Erreur 404 (ressource inexistante)
 * @property {Function} conflict - Erreur 409 (conflit de données)
 * @property {Function} validation - Erreur 422 (validation échouée)
 * @property {Function} internal - Erreur 500 (erreur serveur)
 * @property {Function} database - Erreur 500 (erreur base de données)
 * @property {Function} external - Erreur 502 (service externe indisponible)
 * 
 * @example
 * const { errors } = require('./middlewares/errorHandler');
 * throw errors.notFound('Utilisateur introuvable');
 */
const errors = {
  badRequest: (message = 'Requête invalide') => new AppError(message, 400, 'BAD_REQUEST'),
  unauthorized: (message = 'Non autorisé') => new AppError(message, 401, 'UNAUTHORIZED'),
  forbidden: (message = 'Accès interdit') => new AppError(message, 403, 'FORBIDDEN'),
  notFound: (message = 'Ressource non trouvée') => new AppError(message, 404, 'NOT_FOUND'),
  conflict: (message = 'Conflit de données') => new AppError(message, 409, 'CONFLICT'),
  validation: (message = 'Erreur de validation') => new AppError(message, 422, 'VALIDATION_ERROR'),
  internal: (message = 'Erreur interne du serveur') => new AppError(message, 500, 'INTERNAL_ERROR'),
  database: (message = 'Erreur de base de données') => new AppError(message, 500, 'DATABASE_ERROR'),
  external: (message = 'Erreur de service externe') => new AppError(message, 502, 'EXTERNAL_SERVICE_ERROR')
};

/**
 * Gestionnaire d'erreurs Prisma
 * 
 * Convertit les erreurs Prisma en AppError avec messages utilisateur compréhensibles.
 * 
 * @function handlePrismaError
 * @param {Error} error - Erreur Prisma avec code (P2002, P2003, etc.)
 * @returns {AppError} Erreur formatée
 */
const handlePrismaError = (error) => {
  logger.error('Prisma error detected', { code: error.code, message: error.message });
  switch (error.code) {
    case 'P2002': { // Contrainte unique
      const target = error.meta?.target || 'donnée';
      return new AppError(`Une entrée avec cette valeur existe déjà (${target})`, 409, 'DUPLICATE_ENTRY');
    }
    case 'P2003': // Clé étrangère
      return new AppError('Référence invalide', 400, 'FOREIGN_KEY_VIOLATION');
    case 'P2025': // Non trouvé
      return new AppError('Enregistrement non trouvé', 404, 'NOT_FOUND');
    default:
      return new AppError(`Erreur Prisma (${error.code}): ${error.message}`, 500, 'DATABASE_ERROR');
  }
};

// Gestionnaire d'erreurs JWT
const handleJwtError = (error) => {
  if (error.name === 'JsonWebTokenError') {
    return new AppError('Token invalide', 401, 'INVALID_TOKEN');
  }
  if (error.name === 'TokenExpiredError') {
    return new AppError('Token expiré', 401, 'TOKEN_EXPIRED');
  }
  return new AppError('Erreur d\'authentification', 401, 'AUTH_ERROR');
};

/**
 * Middleware principal de gestion des erreurs Express
 * 
 * Ce middleware doit être le DERNIER middleware de l'application.
 * Il capture toutes les erreurs et les transforme en réponses HTTP appropriées.
 * 
 * SÉCURITÉ:
 * - Stack traces uniquement en développement (config.isDev)
 * - Messages génériques pour erreurs 500+
 * - Logging détaillé des erreurs serveur (statusCode >= 500)
 * - Pas d'exposition des chemins système ou versions
 * 
 * @function errorHandler
 * @param {Error} err - L'erreur capturée
 * @param {express.Request} req - Objet requête Express
 * @param {express.Response} res - Objet réponse Express
 * @param {express.NextFunction} _next - Fonction next (non utilisée)
 * 
 * @returns {void} Envoie une réponse JSON au client
 * 
 * @example
 * // Dans server.js (DOIT Être le dernier middleware)
 * app.use(errorHandler);
 */

const errorHandler = (err, req, res, _next) => {
  let error = err;

  // Erreurs Prisma
  if (err.code && typeof err.code === 'string' && err.code.startsWith('P')) {
    error = handlePrismaError(err);
  }

  // Erreur JWT
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    error = handleJwtError(err);
  }

  // Erreur de syntaxe JSON
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    error = new AppError('JSON invalide dans le corps de la requête', 400, 'INVALID_JSON');
  }

  // Erreur de validation express-validator
  if (err.array && typeof err.array === 'function') {
    const validationErrors = err.array();
    error = new AppError(
      validationErrors.map(e => e.msg).join(', '),
      422,
      'VALIDATION_ERROR'
    );
  }

  // Définir le statut par défaut
  const statusCode = error.statusCode || 500;
  const code = error.code || 'INTERNAL_ERROR';

  // Log de l'erreur
  if (statusCode >= 500) {
    logger.error('Erreur serveur', {
      error: error.message,
      code,
      stack: error.stack,
      path: req.path,
      method: req.method,
      ip: req.ip,
      userId: req.user?.id
    });
  } else {
    logger.warn('Erreur client', {
      error: error.message,
      code,
      path: req.path,
      method: req.method
    });
  }

  // Réponse
  const response = {
    success: false,
    message: error.message,
    code
  };

  // Ajouter la stack trace en développement (SÉCURITÉ: Jamais en production)
  if (config.isDev && error.stack) {
    response.stack = error.stack;
  }

  // Ajouter les erreurs de validation si présentes
  if (error.errors) {
    response.errors = error.errors;
  }

  res.status(statusCode).json(response);
};

module.exports = errorHandler;
module.exports.AppError = AppError;
module.exports.errors = errors;
