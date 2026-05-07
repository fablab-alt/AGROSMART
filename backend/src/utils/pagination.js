/**
 * Utilitaires de pagination standardisée
 * AgroSmart - Backend
 * 
 * Format de réponse standard pour toutes les listes paginées:
 * {
 *   success: true,
 *   data: [...],
 *   pagination: {
 *     page: 1,
 *     limit: 20,
 *     total: 100,
 *     totalPages: 5,
 *     hasNextPage: true,
 *     hasPrevPage: false
 *   }
 * }
 */

/**
 * Parse les paramètres de pagination depuis la requête
 * @param {Object} query - req.query
 * @param {Object} defaults - Valeurs par défaut
 * @returns {Object} { page, limit, skip }
 */
const parsePaginationParams = (query, defaults = {}) => {
    const defaultLimit = defaults.limit || 20;
    const maxLimit = defaults.maxLimit || 100;
    
    let page = parseInt(query.page, 10) || 1;
    let limit = parseInt(query.limit, 10) || defaultLimit;
    
    // Validation
    page = Math.max(1, page);
    limit = Math.min(Math.max(1, limit), maxLimit);
    
    const skip = (page - 1) * limit;
    
    return { page, limit, skip };
};

/**
 * Construit l'objet de pagination pour la réponse
 * @param {number} page - Page courante
 * @param {number} limit - Nombre d'éléments par page
 * @param {number} total - Nombre total d'éléments
 * @returns {Object} Objet pagination
 */
const buildPaginationMeta = (page, limit, total) => {
    const totalPages = Math.ceil(total / limit);
    
    return {
        page,
        limit,
        total,
        totalPages,
        hasNextPage: page < totalPages,
        hasPrevPage: page > 1
    };
};

/**
 * Construit une réponse paginée standardisée
 * @param {Array} data - Les données de la page
 * @param {number} page - Page courante
 * @param {number} limit - Limite par page
 * @param {number} total - Total des éléments
 * @param {Object} extras - Données supplémentaires à inclure
 * @returns {Object} Réponse formatée
 */
const buildPaginatedResponse = (data, page, limit, total, extras = {}) => {
    return {
        success: true,
        data,
        pagination: buildPaginationMeta(page, limit, total),
        ...extras
    };
};

/**
 * Middleware express pour ajouter les helpers de pagination à req
 */
const paginationMiddleware = (defaults = {}) => (req, res, next) => {
    const { page, limit, skip } = parsePaginationParams(req.query, defaults);
    
    req.pagination = { page, limit, skip };
    
    // Helper pour construire la réponse
    res.paginate = (data, total, extras = {}) => {
        return res.json(buildPaginatedResponse(data, page, limit, total, extras));
    };
    
    next();
};

/**
 * Construit les options Prisma pour la pagination
 * @param {Object} pagination - { page, limit, skip }
 * @returns {Object} { skip, take }
 */
const buildPrismaOptions = (pagination) => ({
    skip: pagination.skip,
    take: pagination.limit
});

/**
 * Parse les options de tri depuis la requête
 * @param {Object} query - req.query
 * @param {Array} allowedFields - Champs autorisés pour le tri
 * @param {Object} defaultSort - Tri par défaut
 * @returns {Object} Options de tri pour Prisma
 */
const parseSortParams = (query, allowedFields = [], defaultSort = { createdAt: 'desc' }) => {
    const { sortBy, sortOrder } = query;
    
    if (!sortBy || !allowedFields.includes(sortBy)) {
        return defaultSort;
    }
    
    const order = sortOrder?.toLowerCase() === 'asc' ? 'asc' : 'desc';
    return { [sortBy]: order };
};

module.exports = {
    parsePaginationParams,
    buildPaginationMeta,
    buildPaginatedResponse,
    paginationMiddleware,
    buildPrismaOptions,
    parseSortParams
};
