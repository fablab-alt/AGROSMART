/**
 * Validateurs pour l'authentification
 * AgroSmart - Système Agricole Intelligent
 */

const { body, param } = require('express-validator');

/**
 * Validation pour l'inscription
 */
const registerValidation = [
    body('telephone')
        .trim()
        .matches(/^(07|05|01)\d{8}$/)
        .withMessage('Numéro de téléphone ivoirien invalide (format: 07/05/01 + 8 chiffres)'),

    body('email')
        .optional({ nullable: true, checkFalsy: true })
        .trim()
        .isEmail()
        .normalizeEmail()
        .withMessage('Email invalide'),

    body('password')
        .isLength({ min: 8 })
        .withMessage('Le mot de passe doit contenir au moins 8 caractères')
        .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
        .withMessage('Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre'),

    body('nom')
        .trim()
        .isLength({ min: 2, max: 100 })
        .matches(/^[a-zA-ZÀ-ÿ\s'-]+$/)
        .withMessage('Nom invalide (2-100 caractères, lettres uniquement)'),

    body('prenoms')
        .optional()
        .trim()
        .isLength({ min: 2, max: 100 })
        .matches(/^[a-zA-ZÀ-ÿ\s'-]+$/)
        .withMessage('Prénoms invalides (2-100 caractères, lettres uniquement)'),

    body('prenom')
        .optional()
        .trim()
        .isLength({ min: 2, max: 100 })
        .matches(/^[a-zA-ZÀ-ÿ\s'-]+$/)
        .withMessage('Prénom invalide (2-100 caractères, lettres uniquement)'),

    body('langue_preferee')
        .optional()
        .isIn(['fr', 'baoule', 'malinke', 'senoufo'])
        .withMessage('Langue non supportée')
];

/**
 * Validation pour la connexion
 */
const loginValidation = [
    body('identifier')
        .trim()
        .notEmpty()
        .withMessage('Email ou téléphone requis'),

    body('password')
        .notEmpty()
        .withMessage('Mot de passe requis')
];

/**
 * Validation pour la vérification OTP
 */
const verifyOtpValidation = [
    body('identifier')
        .trim()
        .notEmpty()
        .withMessage('Identifiant requis'),

    body('otp')
        .trim()
        .isLength({ min: 6, max: 6 })
        .isNumeric()
        .withMessage('Code OTP invalide (6 chiffres requis)')
];

/**
 * Validation pour la réinitialisation du mot de passe
 */
const resetPasswordValidation = [
    body('identifier')
        .trim()
        .notEmpty()
        .withMessage('Identifiant requis'),

    body('otp')
        .trim()
        .isLength({ min: 6, max: 6 })
        .isNumeric()
        .withMessage('Code OTP invalide'),

    body('newPassword')
        .isLength({ min: 8 })
        .withMessage('Le mot de passe doit contenir au moins 8 caractères')
        .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
        .withMessage('Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre')
];

/**
 * Validation pour le changement de mot de passe
 */
const changePasswordValidation = [
    body('currentPassword')
        .notEmpty()
        .withMessage('Mot de passe actuel requis'),

    body('newPassword')
        .isLength({ min: 8 })
        .withMessage('Le nouveau mot de passe doit contenir au moins 8 caractères')
        .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
        .withMessage('Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre')
];

/**
 * Validation pour la mise à jour du profil
 */
const updateProfileValidation = [
    body('nom')
        .optional()
        .trim()
        .isLength({ min: 2, max: 100 })
        .matches(/^[a-zA-ZÀ-ÿ\s'-]+$/)
        .withMessage('Nom invalide'),

    body('prenoms')
        .optional()
        .trim()
        .isLength({ min: 2, max: 100 })
        .matches(/^[a-zA-ZÀ-ÿ\s'-]+$/)
        .withMessage('Prénoms invalides'),

    body('langue_preferee')
        .optional()
        .isIn(['fr', 'baoule', 'malinke', 'senoufo'])
        .withMessage('Langue non supportée'),

    body('village')
        .optional()
        .trim()
        .isLength({ max: 200 })
        .withMessage('Nom du village trop long'),

    body('type_producteur')
        .optional()
        .isIn(['individuel', 'cooperatif', 'entreprise'])
        .withMessage('Type de producteur invalide'),

    body('notifications_sms')
        .optional()
        .isBoolean()
        .withMessage('Valeur booléenne requise'),

    body('notifications_whatsapp')
        .optional()
        .isBoolean()
        .withMessage('Valeur booléenne requise'),

    body('notifications_push')
        .optional()
        .isBoolean()
        .withMessage('Valeur booléenne requise')
];

module.exports = {
    registerValidation,
    loginValidation,
    verifyOtpValidation,
    resetPasswordValidation,
    changePasswordValidation,
    updateProfileValidation
};
