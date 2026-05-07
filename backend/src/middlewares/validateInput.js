/**
 * Middleware de validation des entrées
 * AgroSmart - Système Agricole Intelligent
 */

const { validationResult } = require('express-validator');
const { errors } = require('./errorHandler');
const logger = require('../utils/logger');

/**
 * Middleware pour valider les résultats de express-validator
 */
const validateInput = (req, res, next) => {
    const validationErrors = validationResult(req);

    if (!validationErrors.isEmpty()) {
        const errors = validationErrors.array();

        // Logger les tentatives avec données invalides (potentiellement malicieuses)
        logger.warn('Validation failed', {
            path: req.path,
            method: req.method,
            errors: errors.map(e => ({ field: e.param, message: e.msg })),
            ip: req.ip,
            userAgent: req.get('user-agent')
        });

        // Formater les erreurs pour la réponse
        const formattedErrors = errors.reduce((acc, error) => {
            acc[error.param] = error.msg;
            return acc;
        }, {});

        return res.status(422).json({
            success: false,
            message: 'Erreur de validation des données',
            code: 'VALIDATION_ERROR',
            errors: formattedErrors
        });
    }

    next();
};

module.exports = validateInput;
