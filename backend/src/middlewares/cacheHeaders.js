/**
 * Response Caching Middleware for AgroSmart
 * Implements HTTP caching headers for performance optimization
 */

const config = require('../config');

/**
 * Cache duration presets (in seconds)
 */
const CacheDuration = {
  NONE: 0,
  SHORT: 60,           // 1 minute - real-time data
  MEDIUM: 300,         // 5 minutes - frequently updated
  LONG: 3600,          // 1 hour - semi-static data
  VERY_LONG: 86400,    // 24 hours - static content
  WEEK: 604800,        // 7 days - rarely changing
};

/**
 * Cache control directives
 */
const CacheControl = {
  // No caching at all
  noStore: () => 'no-store, no-cache, must-revalidate, proxy-revalidate',
  
  // Private cache (only browser, not CDN/proxy)
  private: (maxAge) => `private, max-age=${maxAge}`,
  
  // Public cache (CDN, proxies can cache)
  public: (maxAge, sMaxAge) => 
    `public, max-age=${maxAge}, s-maxage=${sMaxAge || maxAge}`,
  
  // Immutable (won't change)
  immutable: (maxAge) => `public, max-age=${maxAge}, immutable`,
  
  // Stale while revalidate
  staleWhileRevalidate: (maxAge, staleTime) => 
    `public, max-age=${maxAge}, stale-while-revalidate=${staleTime}`,
};

/**
 * Default cache policies by route type
 */
const CachePolicies = {
  // User-specific data - private only
  user: {
    cacheControl: CacheControl.private(CacheDuration.SHORT),
    vary: 'Authorization',
  },
  
  // Real-time data - no cache
  realtime: {
    cacheControl: CacheControl.noStore(),
    vary: null,
  },
  
  // Public listings - CDN cacheable
  listings: {
    cacheControl: CacheControl.public(CacheDuration.MEDIUM, CacheDuration.LONG),
    vary: 'Accept-Language',
  },
  
  // Weather data - short cache
  weather: {
    cacheControl: CacheControl.staleWhileRevalidate(CacheDuration.SHORT, CacheDuration.MEDIUM),
    vary: null,
  },
  
  // Static reference data
  reference: {
    cacheControl: CacheControl.public(CacheDuration.VERY_LONG, CacheDuration.WEEK),
    vary: 'Accept-Language',
  },
  
  // Static assets
  static: {
    cacheControl: CacheControl.immutable(CacheDuration.WEEK),
    vary: null,
  },
};

/**
 * Set cache headers middleware factory
 * @param {Object} options - Cache options
 * @returns {Function} Express middleware
 */
function setCacheHeaders(options = {}) {
  const {
    policy = 'user',
    maxAge,
    customCacheControl,
    vary,
    etag = true,
    lastModified,
  } = options;

  // Get policy defaults
  const policyConfig = CachePolicies[policy] || CachePolicies.user;
  
  return (req, res, next) => {
    // Skip caching in development unless explicitly enabled
    if (config.isDev && !process.env.ENABLE_DEV_CACHE) {
      res.set('Cache-Control', CacheControl.noStore());
      return next();
    }

    // Don't cache non-GET requests
    if (req.method !== 'GET' && req.method !== 'HEAD') {
      res.set('Cache-Control', CacheControl.noStore());
      return next();
    }

    // Set Cache-Control
    const cacheControlValue = customCacheControl || 
      (maxAge ? CacheControl.private(maxAge) : policyConfig.cacheControl);
    res.set('Cache-Control', cacheControlValue);

    // Set Vary header
    const varyValue = vary !== undefined ? vary : policyConfig.vary;
    if (varyValue) {
      res.set('Vary', varyValue);
    }

    // Set Last-Modified if provided
    if (lastModified) {
      res.set('Last-Modified', lastModified.toUTCString());
    }

    // Disable default express etag if using custom
    if (!etag) {
      res.set('ETag', null);
    }

    next();
  };
}

/**
 * Conditional GET middleware (304 responses)
 * Must be used before sending response
 */
function conditionalGet(req, res, data, options = {}) {
  const { lastModified, etag } = options;

  // Check If-None-Match (ETag)
  if (etag) {
    res.set('ETag', etag);
    const clientEtag = req.get('If-None-Match');
    if (clientEtag && clientEtag === etag) {
      return res.status(304).end();
    }
  }

  // Check If-Modified-Since
  if (lastModified) {
    res.set('Last-Modified', lastModified.toUTCString());
    const clientDate = req.get('If-Modified-Since');
    if (clientDate) {
      const clientTimestamp = new Date(clientDate).getTime();
      const serverTimestamp = lastModified.getTime();
      if (clientTimestamp >= serverTimestamp) {
        return res.status(304).end();
      }
    }
  }

  // Return data for normal response
  return data;
}

/**
 * Generate ETag from data
 * @param {Object|string} data - Response data
 * @returns {string} ETag value
 */
function generateEtag(data) {
  const crypto = require('crypto');
  const content = typeof data === 'string' ? data : JSON.stringify(data);
  return `"${crypto.createHash('md5').update(content).digest('hex')}"`;
}

/**
 * Route-specific cache middleware
 */
const cacheMiddleware = {
  // No cache for auth/sensitive routes
  noCache: setCacheHeaders({ 
    customCacheControl: CacheControl.noStore() 
  }),
  
  // User-specific data
  userCache: setCacheHeaders({ 
    policy: 'user',
    maxAge: CacheDuration.SHORT 
  }),
  
  // Marketplace listings (can be CDN cached)
  listingsCache: setCacheHeaders({ 
    policy: 'listings' 
  }),
  
  // Weather data
  weatherCache: setCacheHeaders({ 
    policy: 'weather' 
  }),
  
  // Reference data (regions, cultures, etc.)
  referenceCache: setCacheHeaders({ 
    policy: 'reference' 
  }),
  
  // Static assets
  staticCache: setCacheHeaders({ 
    policy: 'static' 
  }),
  
  // Real-time sensor data
  realtimeCache: setCacheHeaders({ 
    policy: 'realtime' 
  }),
};

/**
 * Apply default cache headers to response
 * Can be called from controllers
 */
function applyCacheHeaders(res, policy = 'user', options = {}) {
  const policyConfig = CachePolicies[policy] || CachePolicies.user;
  res.set('Cache-Control', options.cacheControl || policyConfig.cacheControl);
  if (policyConfig.vary) {
    res.set('Vary', policyConfig.vary);
  }
}

module.exports = {
  CacheDuration,
  CacheControl,
  CachePolicies,
  setCacheHeaders,
  conditionalGet,
  generateEtag,
  cacheMiddleware,
  applyCacheHeaders,
};
