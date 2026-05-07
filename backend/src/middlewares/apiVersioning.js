/**
 * Middleware de versioning API
 * AgroSmart - Backend
 * 
 * Gère le versioning de l'API via:
 * - Chemin URL: /api/v1/, /api/v2/
 * - Header Accept-Version
 * - Query param: ?version=1
 */

const config = require('../config');
const logger = require('../utils/logger');

// Versions supportées de l'API
const SUPPORTED_VERSIONS = ['1', '2'];
const DEFAULT_VERSION = '1';
const CURRENT_VERSION = config.server?.apiVersion?.replace('v', '') || '1';

/**
 * Middleware qui extrait et valide la version de l'API
 */
const versioningMiddleware = () => (req, res, next) => {
    // 1. Extraire la version depuis l'URL (/api/v1/ ou /api/v2/)
    let version = extractVersionFromPath(req.path);
    
    // 2. Si pas dans l'URL, vérifier le header Accept-Version
    if (!version) {
        version = req.headers['accept-version'];
    }
    
    // 3. Sinon, vérifier query param
    if (!version) {
        version = req.query.version;
    }
    
    // 4. Utiliser la version par défaut si non spécifiée
    version = version || DEFAULT_VERSION;
    
    // Normaliser la version (retirer 'v' si présent)
    version = version.toString().replace(/^v/i, '');
    
    // Valider la version
    if (!SUPPORTED_VERSIONS.includes(version)) {
        return res.status(400).json({
            success: false,
            code: 'UNSUPPORTED_API_VERSION',
            message: `Version API '${version}' non supportée. Versions disponibles: ${SUPPORTED_VERSIONS.map(v => 'v' + v).join(', ')}`,
            supportedVersions: SUPPORTED_VERSIONS.map(v => 'v' + v)
        });
    }
    
    // Ajouter la version à la requête pour utilisation dans les controllers
    req.apiVersion = version;
    
    // Ajouter le header de version à la réponse
    res.setHeader('X-API-Version', `v${version}`);
    
    // Warning pour versions obsolètes
    if (version !== CURRENT_VERSION) {
        res.setHeader('X-API-Deprecation-Warning', `API v${version} sera obsolète. Migrez vers v${CURRENT_VERSION}.`);
        logger.debug(`Requête utilisant API v${version} (version courante: v${CURRENT_VERSION})`);
    }
    
    next();
};

/**
 * Extrait la version depuis le chemin de l'URL
 * @param {string} path - Chemin de l'URL
 * @returns {string|null} Version extraite ou null
 */
function extractVersionFromPath(path) {
    const match = path.match(/\/api\/v(\d+)\//i);
    return match ? match[1] : null;
}

/**
 * Helper pour vérifier la version minimale requise dans un controller
 * @param {Object} req - Express request
 * @param {string} minVersion - Version minimale requise
 * @returns {boolean}
 */
const requireMinVersion = (req, minVersion) => {
    const reqVersion = parseInt(req.apiVersion, 10);
    const min = parseInt(minVersion.replace(/^v/i, ''), 10);
    return reqVersion >= min;
};

/**
 * Decorator pour les routes spécifiques à une version
 * Usage: router.get('/feature', forVersion('2'), controller)
 */
const forVersion = (...versions) => (req, res, next) => {
    const normalizedVersions = versions.map(v => v.toString().replace(/^v/i, ''));
    
    if (!normalizedVersions.includes(req.apiVersion)) {
        return res.status(404).json({
            success: false,
            code: 'ROUTE_NOT_AVAILABLE',
            message: `Cette fonctionnalité n'est pas disponible en v${req.apiVersion}`
        });
    }
    
    next();
};

/**
 * Middleware de deprecation pour marquer une route comme obsolète
 */
const deprecated = (message, sunsetDate) => (req, res, next) => {
    res.setHeader('X-Deprecated', 'true');
    res.setHeader('X-Deprecation-Message', message);
    
    if (sunsetDate) {
        res.setHeader('Sunset', sunsetDate.toISOString());
    }
    
    logger.warn(`Route obsolète accédée: ${req.method} ${req.path} - ${message}`);
    next();
};

module.exports = {
    versioningMiddleware,
    requireMinVersion,
    forVersion,
    deprecated,
    SUPPORTED_VERSIONS,
    DEFAULT_VERSION,
    CURRENT_VERSION
};
