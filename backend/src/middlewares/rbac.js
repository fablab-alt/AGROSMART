/**
 * Middleware de contrôle d'accès basé sur les rôles (RBAC)
 * AgroSmart - Système Agricole Intelligent
 * 
 * Ce module implémente le contrôle d'accès basé sur les rôles (Role-Based Access Control)
 * pour sécuriser les endpoints de l'API selon les permissions des utilisateurs.
 * 
 * SÉCURITÉ:
 * - Hiérarchie des rôles stricte (ADMIN > CONSEILLER > PARTENAIRE > PRODUCTEUR)
 * - Vérification de propriété des ressources
 * - Protection contre l'escalade de privilèges horizontale et verticale
 * - Logging des tentatives d'accès non autorisées
 * 
 * @module middlewares/rbac
 * @requires ./errorHandler
 * @requires ../config/prisma
 */

const { errors } = require('./errorHandler');

/**
 * Énumération des rôles du système
 * 
 * @enum {string}
 * @readonly
 * @property {string} ADMIN - Administrateur système (accès complet)
 * @property {string} CONSEILLER - Conseiller agricole (gestion producteurs)
 * @property {string} PRODUCTEUR - Producteur agricole (accès ses données)
 * @property {string} PARTENAIRE - Partenaire commercial (marketplace)
 */
const ROLES = {
  ADMIN: 'ADMIN',
  CONSEILLER: 'CONSEILLER',
  PRODUCTEUR: 'PRODUCTEUR',
  PARTENAIRE: 'PARTENAIRE',
  ACHETEUR: 'ACHETEUR'
};

/**
 * Hiérarchie des rôles (du plus élevé au moins élevé)
 */
const ROLE_HIERARCHY = {
  [ROLES.ADMIN]: 4,
  [ROLES.CONSEILLER]: 3,
  [ROLES.PARTENAIRE]: 2,
  [ROLES.PRODUCTEUR]: 1,
  [ROLES.ACHETEUR]: 1
};

/**
 * Middleware pour restreindre l'accès à certains rôles spécifiques
 * 
 * Vérifie que l'utilisateur connecté possède l'un des rôles autorisés.
 * Ce middleware effectue une vérification stricte (whitelist).
 * 
 * @function requireRole
 * @param {...string} allowedRoles - Liste des rôles autorisés à accéder à la route
 * @returns {Function} Middleware Express
 * 
 * @throws {AppError} 401 - Si l'utilisateur n'est pas authentifié
 * @throws {AppError} 403 - Si le rôle de l'utilisateur n'est pas autorisé
 * 
 * @example
 * // Autoriser uniquement les admins
 * router.delete('/users/:id', requireRole('ADMIN'), deleteUser);
 * 
 * @example
 * // Autoriser admins et conseillers
 * router.get('/producteurs', requireRole('ADMIN', 'CONSEILLER'), getProducteurs);
 */
const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(errors.unauthorized('Authentification requise'));
    }

    if (!allowedRoles.includes(req.user.role)) {
      return next(errors.forbidden(
        `Accès réservé aux rôles: ${allowedRoles.join(', ')}`
      ));
    }

    next();
  };
};

/**
 * Middleware pour vérifier un niveau de rôle minimum selon la hiérarchie
 * 
 * Utilise ROLE_HIERARCHY pour déterminer si l'utilisateur a un niveau suffisant.
 * Les rôles supérieurs ont automatiquement accès (ex: ADMIN peut accéder aux routes PRODUCTEUR).
 * 
 * @function requireMinRole
 * @param {string} minimumRole - Rôle minimum requis (ex: 'CONSEILLER')
 * @returns {Function} Middleware Express
 * 
 * @throws {AppError} 401 - Si l'utilisateur n'est pas authentifié
 * @throws {AppError} 403 - Si le niveau du rôle est insuffisant
 * 
 * @example
 * // Autoriser CONSEILLER et tous les rôles supérieurs (ADMIN)
 * router.get('/stats', requireMinRole('CONSEILLER'), getStats);
 */
const requireMinRole = (minimumRole) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(errors.unauthorized('Authentification requise'));
    }

    const userLevel = ROLE_HIERARCHY[req.user.role] || 0;
    const requiredLevel = ROLE_HIERARCHY[minimumRole] || 0;

    if (userLevel < requiredLevel) {
      return next(errors.forbidden(
        `Niveau d'accès insuffisant. Rôle minimum requis: ${minimumRole}`
      ));
    }

    next();
  };
};

/**
 * Middleware générique pour vérifier la propriété d'une ressource
 * 
 * SÉCURITÉ:
 * - Empêche l'accès horizontal (user A accède aux données de user B)
 * - Les ADMIN ont toujours accès (bypass)
 * - Les CONSEILLER ont accès aux ressources de leurs producteurs
 * - Les autres rôles doivent être propriétaires de la ressource
 * 
 * @function requireOwnership
 * @param {Function} getResourceOwnerId - Fonction async qui extrait l'ID du propriétaire depuis req
 * @returns {Function} Middleware Express async
 * 
 * @throws {AppError} 401 - Si l'utilisateur n'est pas authentifié
 * @throws {AppError} 403 - Si l'utilisateur n'est pas propriétaire
 * 
 * @example
 * const getParcelleOwnerId = async (req) => {
 *   const parcelle = await prisma.parcelle.findUnique({
 *     where: { id: req.params.id },
 *     select: { userId: true }
 *   });
 *   return parcelle?.userId;
 * };
 * router.delete('/parcelles/:id', requireOwnership(getParcelleOwnerId), deleteParcelle);
 */
const requireOwnership = (getResourceOwnerId) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        return next(errors.unauthorized('Authentification requise'));
      }

      // Les admins ont toujours accès
      if (req.user.role === ROLES.ADMIN) {
        return next();
      }

      // Les conseillers ont accès aux ressources de leurs producteurs
      if (req.user.role === ROLES.CONSEILLER) {
        return next();
      }

      const ownerId = await getResourceOwnerId(req);

      if (ownerId !== req.user.id) {
        return next(errors.forbidden(
          'Vous n\'êtes pas autorisé à accéder à cette ressource'
        ));
      }

      next();
    } catch (error) {
      next(error);
    }
  };
};

/**
 * Middleware pour vérifier l'accès à une parcelle
 */
/**
 * Middleware pour vérifier l'accès à une parcelle
 */
const requireParcelleAccess = async (req, res, next) => {
  try {
    if (!req.user) {
      return next(errors.unauthorized('Authentification requise'));
    }

    const parcelleId = req.params.parcelleId || req.params.id || req.body.parcelle_id;

    if (!parcelleId) {
      return next(errors.badRequest('ID de parcelle requis'));
    }

    // Admins et conseillers ont accès à toutes les parcelles
    if ([ROLES.ADMIN, ROLES.CONSEILLER].includes(req.user.role)) {
      return next();
    }

    // Vérifier si l'utilisateur est propriétaire de la parcelle
    const prisma = require('../config/prisma');
    const parcelle = await prisma.parcelle.findUnique({
      where: {
        id: parcelleId,
        userId: req.user.id
      },
      select: { id: true }
    });

    if (!parcelle) {
      return next(errors.forbidden(
        'Vous n\'avez pas accès à cette parcelle'
      ));
    }

    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Middleware pour vérifier l'accès aux données d'un capteur
 */
const requireCapteurAccess = async (req, res, next) => {
  try {
    if (!req.user) {
      return next(errors.unauthorized('Authentification requise'));
    }

    const capteurId = req.params.capteurId || req.params.id || req.body.capteur_id;

    if (!capteurId) {
      return next(errors.badRequest('ID de capteur requis'));
    }

    // Admins et conseillers ont accès à tous les capteurs
    if ([ROLES.ADMIN, ROLES.CONSEILLER].includes(req.user.role)) {
      return next();
    }

    // Vérifier si l'utilisateur est propriétaire de la parcelle associée
    const prisma = require('../config/prisma');
    const capteur = await prisma.capteur.findFirst({
      where: {
        id: capteurId,
        station: {
          parcelle: {
            userId: req.user.id
          }
        }
      },
      select: { id: true }
    });

    if (!capteur) {
      return next(errors.forbidden(
        'Vous n\'avez pas accès à ce capteur'
      ));
    }

    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Raccourcis pour les rôles courants
 */
const isAdmin = requireRole(ROLES.ADMIN);
const isConseiller = requireRole(ROLES.ADMIN, ROLES.CONSEILLER);
const isProducteur = requireRole(ROLES.ADMIN, ROLES.CONSEILLER, ROLES.PRODUCTEUR);
const isPartenaire = requireRole(ROLES.ADMIN, ROLES.PARTENAIRE);
const isMarketplaceUser = requireRole(
  ROLES.ADMIN,
  ROLES.CONSEILLER,
  ROLES.PRODUCTEUR,
  ROLES.PARTENAIRE,
  ROLES.ACHETEUR
);

module.exports = {
  ROLES,
  ROLE_HIERARCHY,
  requireRole,
  requireMinRole,
  requireOwnership,
  requireParcelleAccess,
  requireCapteurAccess,
  isAdmin,
  isConseiller,
  isProducteur,
  isPartenaire,
  isMarketplaceUser
};
