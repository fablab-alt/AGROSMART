/**
 * Middleware de validation des requêtes
 * AgroSmart - Système Agricole Intelligent
 */

const { validationResult, body, param, query } = require('express-validator');
const { AppError } = require('./errorHandler');
const config = require('../config');
const logger = require('../utils/logger');

/**
 * Middleware pour vérifier les résultats de validation
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    const errorMessages = errors.array().map(err => ({
      field: err.path,
      message: err.msg,
      // Ne pas inclure la valeur en production pour éviter les fuites de données
      value: config.isDev ? err.value : undefined
    }));

    // Log seulement en développement, sans valeurs sensibles
    if (config.isDev) {
      const safeErrors = errorMessages.map(({ field, message }) => ({ field, message }));
      logger.debug('Validation errors', { errors: safeErrors });
    }

    // Créer un message explicite avec toutes les erreurs
    const detailedMessage = errorMessages.map(err => `${err.message}`).join('. ');

    const error = new AppError(
      detailedMessage || 'Erreur de validation des données',
      422,
      'VALIDATION_ERROR'
    );
    error.errors = errorMessages;

    return next(error);
  }

  next();
};

/**
 * Validations communes réutilisables
 */
const validators = {
  // UUID
  uuid: (field, location = 'param') => {
    const validator = location === 'param' ? param(field) :
      location === 'body' ? body(field) : query(field);
    return validator
      .isUUID()
      .withMessage(`${field} doit être un UUID valide`);
  },

  // Email (optionnel pour l'inscription)
  email: () => body('email')
    .optional({ nullable: true, checkFalsy: true })
    .isEmail()
    .withMessage('Email invalide')
    .normalizeEmail()
    .isLength({ max: 255 })
    .withMessage('Email trop long (max 255 caractères)'),

  // Téléphone (format ivoirien - plus flexible)
  telephone: () => body('telephone')
    .notEmpty()
    .withMessage('Le numéro de téléphone est requis')
    .matches(/^(\+225)?[0-9]{10}$/)
    .withMessage('Numéro de téléphone invalide (format: +2250123456789 ou 0123456789)'),

  /**
   * Validation du mot de passe avec exigences de sécurité renforcées
   * 
   * SÉCURITÉ:
   * - Minimum 8 caractères (au lieu de 6)
   * - Au moins 1 majuscule
   * - Au moins 1 minuscule  
   * - Au moins 1 chiffre
   * - Rejette les mots de passe communs (dictionary check)
   * 
   * @function password
   * @returns {ValidationChain} Chaîne de validation express-validator
   */
  password: () => body('password')
    .notEmpty()
    .withMessage('Le mot de passe est requis')
    .isLength({ min: 8 })
    .withMessage('Le mot de passe doit contenir au moins 8 caractères')
    .matches(/[A-Z]/)
    .withMessage('Le mot de passe doit contenir au moins une majuscule')
    .matches(/[a-z]/)
    .withMessage('Le mot de passe doit contenir au moins une minuscule')
    .matches(/[0-9]/)
    .withMessage('Le mot de passe doit contenir au moins un chiffre')
    .custom((value) => {
      // Liste de mots de passe communs à rejeter
      const weakPasswords = [
        'password', 'Password', 'PASSWORD',
        '12345678', '123456789', 'qwerty',
        'azerty', 'abc123', 'password123'
      ];

      if (weakPasswords.includes(value.toLowerCase().replace(/[0-9]/g, ''))) {
        throw new Error('Ce mot de passe est trop commun');
      }

      return true;
    }),

  // Nom / Prénom
  nom: () => body('nom')
    .trim()
    .notEmpty()
    .withMessage('Le nom est requis')
    .isLength({ min: 2, max: 100 })
    .withMessage('Le nom doit contenir entre 2 et 100 caractères'),

  prenom: () => body('prenom')
    .trim()
    .notEmpty()
    .withMessage('Le prénom est requis')
    .isLength({ min: 2, max: 100 })
    .withMessage('Le prénom doit contenir entre 2 et 100 caractères'),

  prenoms: () => body('prenoms')
    .trim()
    .notEmpty()
    .withMessage('Les prénoms sont requis')
    .isLength({ min: 2, max: 100 })
    .withMessage('Les prénoms doivent contenir entre 2 et 100 caractères'),

  // OTP
  otp: () => body('otp')
    .isLength({ min: 6, max: 6 })
    .withMessage('Le code OTP doit contenir 6 chiffres')
    .isNumeric()
    .withMessage('Le code OTP doit être numérique'),

  // Coordonnées GPS
  latitude: (field = 'latitude') => body(field)
    .optional({ nullable: true })
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude invalide (doit être entre -90 et 90)'),

  longitude: (field = 'longitude') => body(field)
    .optional({ nullable: true })
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude invalide (doit être entre -180 et 180)'),

  // Surface en hectares
  superficie: () => body('superficie')
    .isFloat({ min: 0.01, max: 10000 })
    .withMessage('Superficie invalide (doit être entre 0.01 et 10000 hectares)'),

  // Pagination
  page: () => query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Le numéro de page doit être un entier positif')
    .toInt(),

  limit: () => query('limit')
    .optional()
    .isInt({ min: 1, max: 500 })
    .withMessage('La limite doit être entre 1 et 500')
    .toInt(),

  // Dates
  date: (field) => body(field)
    .isISO8601()
    .withMessage(`${field} doit être une date valide (format ISO 8601)`)
    .toDate(),

  dateOptional: (field) => body(field)
    .optional()
    .isISO8601()
    .withMessage(`${field} doit être une date valide (format ISO 8601)`)
    .toDate(),

  // Langue
  langue: () => body('langue')
    .optional()
    .isIn(['fr', 'dioula', 'baoule', 'bete'])
    .withMessage('Langue non supportée'),

  langue_preferee: () => body('langue_preferee')
    .optional()
    .isIn(['fr', 'dioula', 'baoule', 'bete'])
    .withMessage('Langue non supportée'),

  // Rôle
  role: () => body('role')
    .isIn(['producteur', 'conseiller', 'admin', 'partenaire'])
    .withMessage('Rôle invalide'),

  // Type de capteur (conforme au schéma PostgreSQL)
  typeCapteur: () => body('type')
    .isIn(['humidite', 'temperature', 'ph', 'npk', 'meteo', 'camera'])
    .withMessage('Type de capteur invalide'),

  // Niveau d'alerte (conforme au schéma PostgreSQL)
  niveauAlerte: () => body('niveau')
    .isIn(['info', 'important', 'critique'])
    .withMessage('Niveau d\'alerte invalide'),

  // Texte optionnel
  textOptional: (field, max = 500) => body(field)
    .optional()
    .trim()
    .isLength({ max })
    .withMessage(`${field} ne peut pas dépasser ${max} caractères`),

  // Texte requis
  textRequired: (field, min = 1, max = 500) => body(field)
    .trim()
    .notEmpty()
    .withMessage(`${field} est requis`)
    .isLength({ min, max })
    .withMessage(`${field} doit contenir entre ${min} et ${max} caractères`),

  // Nombre positif
  positiveNumber: (field) => body(field)
    .isFloat({ min: 0 })
    .withMessage(`${field} doit être un nombre positif`),

  // Entier positif
  positiveInt: (field) => body(field)
    .isInt({ min: 0 })
    .withMessage(`${field} doit être un entier positif`)
    .toInt(),

  // Tableau non vide
  arrayNotEmpty: (field) => body(field)
    .isArray({ min: 1 })
    .withMessage(`${field} doit être un tableau non vide`),

  // Boolean
  boolean: (field) => body(field)
    .isBoolean()
    .withMessage(`${field} doit être un booléen`)
    .toBoolean()
};

/**
 * Schémas de validation prédéfinis
 */
const schemas = {
  // Inscription
  register: [
    // validators.email(), // Email est optionnel, validé dans le controller
    validators.telephone(),
    validators.password(),
    validators.nom(),
    validators.prenoms(),
    validators.langue_preferee(),
    // Champs agricoles optionnels
    body('production_3_mois_precedents_kg')
      .optional({ nullable: true })
      .isFloat({ min: 0 })
      .withMessage('La production doit être un nombre positif')
      .toFloat(),
    body('superficie_exploitee')
      .optional({ nullable: true })
      .isFloat({ min: 0 })
      .withMessage('La superficie doit être un nombre positif')
      .toFloat(),
    body('unite_superficie')
      .optional({ nullable: true })
      .isIn(['ha', 'm2'])
      .withMessage('L\'unité doit être "ha" ou "m2"'),
    body('region_id')
      .optional({ nullable: true })
      .isString()
      .withMessage('L\'identifiant de région doit être une chaîne'),
    body('productions')
      .optional()
      .isArray()
      .withMessage('Productions doit être un tableau'),
    body('productions.*.type')
      .optional()
      .isString()
      .withMessage('Le type de production doit être une chaîne'),
    body('productions.*.surface')
      .optional()
      .isFloat({ min: 0 })
      .withMessage('La surface doit être un nombre positif'),
    validate
  ],

  // Connexion
  login: [
    body('identifier')
      .notEmpty()
      .withMessage('Email ou téléphone requis'),
    body('password')
      .notEmpty()
      .withMessage('Mot de passe requis'),
    validate
  ],

  // Vérification OTP
  verifyOtp: [
    validators.otp(),
    body('identifier')
      .notEmpty()
      .withMessage('Email ou téléphone requis'),
    validate
  ],

  // Création de parcelle
  createParcelle: [
    validators.textRequired('nom', 2, 100),
    validators.superficie(),
    validators.latitude(),
    validators.longitude(),
    validators.textOptional('description', 1000),
    body('type_sol')
      .optional()
      .isIn(['argileux', 'sablonneux', 'limono_argileux', 'limoneux', 'argilo_sableux'])
      .withMessage('Type de sol invalide'),
    body('status')
      .optional()
      .isIn(['ACTIVE', 'EN_REPOS', 'PREPAREE', 'ENSEMENCEE', 'EN_CROISSANCE', 'RECOLTE'])
      .withMessage('Statut invalide. Valeurs acceptées: ACTIVE, EN_REPOS, PREPAREE, ENSEMENCEE, EN_CROISSANCE, RECOLTE'),
    body('culture')
      .optional()
      .isString()
      .trim(),
    body('date_plantation')
      .optional()
      .isISO8601()
      .withMessage('Date de plantation invalide'),
    validate
  ],

  // Création de station
  createStation: [
    validators.textRequired('nom', 2, 100),
    validators.uuid('parcelle_id', 'body'),
    validators.latitude('latitude'),
    validators.longitude('longitude'),
    validate
  ],

  // Création de capteur
  createCapteur: [
    validators.uuid('station_id', 'body').optional({ nullable: true }),
    validators.uuid('parcelle_id', 'body').optional({ nullable: true }),
    validators.typeCapteur(),
    validators.textOptional('modele', 50),
    validators.textOptional('numero_serie', 100),
    validate
  ],

  // Envoi de mesure
  sendMesure: [
    validators.uuid('capteur_id', 'body'),
    body('valeur')
      .isFloat()
      .withMessage('La valeur doit être un nombre'),
    body('unite')
      .optional()
      .isString()
      .isLength({ max: 20 }),
    validators.dateOptional('timestamp'),
    validate
  ],

  // Pagination
  pagination: [
    validators.page(),
    validators.limit(),
    validate
  ],

  // Paramètre UUID
  paramUuid: (field = 'id') => [
    validators.uuid(field, 'param'),
    validate
  ]
};

module.exports = {
  validate,
  validators,
  schemas,
  body,
  param,
  query,
  validationResult
};
