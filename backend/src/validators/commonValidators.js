/**
 * Validateurs communs réutilisables
 * AgroSmart - Système Agricole Intelligent
 */

const { param, query } = require('express-validator');

/**
 * Validation pour les IDs (UUID ou entiers)
 */
const idValidation = [
    param('id')
        .trim()
        .notEmpty()
        .withMessage('ID requis')
        .custom((value) => {
            // Vérifier si c'est un UUID ou un entier
            const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
            const isInt = /^\d+$/.test(value);

            if (!isUUID && !isInt) {
                throw new Error('Format ID invalide');
            }
            return true;
        })
];

/**
 * Validation pour la pagination
 */
const paginationValidation = [
    query('page')
        .optional()
        .isInt({ min: 1 })
        .withMessage('Le numéro de page doit être un entier positif')
        .toInt(),

    query('limit')
        .optional()
        .isInt({ min: 1, max: 100 })
        .withMessage('La limite doit être entre 1 et 100')
        .toInt(),

    query('sort')
        .optional()
        .isIn(['asc', 'desc'])
        .withMessage('Le tri doit être "asc" ou "desc"')
];

/**
 * Validation pour les recherches textuelles
 */
const searchValidation = [
    query('q')
        .optional()
        .trim()
        .isLength({ min: 2, max: 200 })
        .withMessage('La recherche doit contenir entre 2 et 200 caractères')
        .matches(/^[a-zA-Z0-9À-ÿ\s'-]+$/)
        .withMessage('Caractères invalides dans la recherche')
];

/**
 * Validation pour les dates
 */
const dateRangeValidation = [
    query('startDate')
        .optional()
        .isISO8601()
        .withMessage('Format de date invalide (ISO 8601 requis)')
        .toDate(),

    query('endDate')
        .optional()
        .isISO8601()
        .withMessage('Format de date invalide (ISO 8601 requis)')
        .toDate()
        .custom((endDate, { req }) => {
            if (req.query.startDate && new Date(endDate) < new Date(req.query.startDate)) {
                throw new Error('La date de fin doit être après la date de début');
            }
            return true;
        })
];

/**
 * Sanitizer pour empêcher les attaques NoSQL, XSS et Command Injection
 * 
 * SÉCURITÉ:
 * Cette fonction nettoie les entrées utilisateur pour prévenir:
 * - XSS (Cross-Site Scripting) : Suppression des balises HTML et scripts
 * - NoSQL Injection : Suppression des caractères MongoDB ($, {, })
 * - Command Injection : Suppression des caractères shell dangereux
 * 
 * LIMITATIONS:
 * - Ne pas utiliser pour les champs où HTML est attendu (utiliser DOMPurify côté client)
 * - Les caractères légitimes < et > sont également supprimés
 * 
 * @function sanitizeString
 * @param {string|*} str - Chaîne à nettoyer (autres types retournés tels quels)
 * @returns {string|*} Chaîne nettoyée ou valeur originale si non-string
 * 
 * @example
 * sanitizeString('<script>alert("XSS")</script>')
 * // Retourne: 'scriptalert("XSS")/script'
 * 
 * sanitizeString('{ $ne: null }')
 * // Retourne: '  ne: null '
 * 
 * @see {@link https://owasp.org/www-community/attacks/xss/|OWASP XSS}
 * @see {@link https://owasp.org/www-community/attacks/Command_Injection|OWASP Command Injection}
 */
const sanitizeString = (str) => {
    // Si ce n'est pas une chaîne, retourner tel quel
    if (typeof str !== 'string') return str;

    // Supprimer les caractères potentiellement dangereux
    return str
        // Prévention XSS : Supprimer les balises HTML
        .replace(/<\/?[^>]+(>|$)/g, '') // Balises HTML complètes
        .replace(/</g, '')  // Chevrons simples restants
        .replace(/>/g, '')

        // Prévention NoSQL Injection (MongoDB)
        .replace(/\$/g, '')  // Opérateurs MongoDB
        .replace(/\{/g, '')  // Accolades ouvrantes
        .replace(/\}/g, '')  // Accolades fermantes

        // Prévention Command Injection
        .replace(/[;|&`]/g, '')  // Séparateurs de commandes shell

        // Prévention événements JavaScript inline
        .replace(/on\w+\s*=/gi, '')  // onclick=, onload=, etc.

        // Normalisation : Supprimer espaces multiples et trim
        .replace(/\s+/g, ' ')
        .trim();
};

module.exports = {
    idValidation,
    paginationValidation,
    searchValidation,
    dateRangeValidation,
    sanitizeString
};
