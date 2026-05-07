/**
 * Middleware Admin
 * AgroSmart - Backend API
 * 
 * Middleware simplifié pour vérifier les permissions administrateur
 */

const { requireRole, ROLES } = require('./rbac');

/**
 * Middleware qui vérifie que l'utilisateur est administrateur
 * @middleware
 */
const adminMiddleware = requireRole(ROLES.ADMIN);

/**
 * Middleware qui vérifie que l'utilisateur est admin ou conseiller
 * @middleware
 */
const adminOrConseillerMiddleware = requireRole(ROLES.ADMIN, ROLES.CONSEILLER);

module.exports = {
  adminMiddleware,
  adminOrConseillerMiddleware,
  ROLES
};
