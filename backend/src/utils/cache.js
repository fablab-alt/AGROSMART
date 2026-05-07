/**
 * Service de cache mémoire local
 * AgroSmart - Système Agricole Intelligent
 */

const logger = require('./logger');

// TTL par défaut en secondes
const TTL = {
  WEATHER: 30 * 60,
  WEATHER_FORECAST: 60 * 60,
  PARCELLES: 5 * 60,
  SENSORS: 60,
  MARKETPLACE: 10 * 60,
  USER_PROFILE: 15 * 60,
  FORMATIONS: 60 * 60,
  REGIONS: 24 * 60 * 60,
  DEFAULT: 60 * 60
};

// Préfixes de clés
const PREFIXES = {
  WEATHER: 'weather',
  PARCELLES: 'parcelles',
  SENSORS: 'sensors',
  MARKETPLACE: 'marketplace',
  USER: 'user',
  FORMATIONS: 'formations',
  REGIONS: 'regions',
  SESSION: 'session'
};

// Store mémoire process-local
const store = new Map();

const now = () => Date.now();

const buildRecord = (value, ttlSeconds) => {
  const expiresAt = ttlSeconds ? now() + ttlSeconds * 1000 : null;
  return { value, expiresAt };
};

const isExpired = (record) => record.expiresAt !== null && record.expiresAt <= now();

const matchesPattern = (key, pattern) => {
  if (pattern.endsWith('*')) {
    return key.startsWith(pattern.slice(0, -1));
  }
  return key === pattern;
};

const cache = {
  get: async (key) => {
    try {
      const record = store.get(key);
      if (!record) return null;
      if (isExpired(record)) {
        store.delete(key);
        return null;
      }
      return record.value;
    } catch (error) {
      logger.warn(`[Cache] Get Error: ${key}`, { error: error.message });
      return null;
    }
  },

  set: async (key, value, ttlSeconds = TTL.DEFAULT) => {
    try {
      store.set(key, buildRecord(value, ttlSeconds));
      logger.debug(`[Cache] Set: ${key}`, { ttl: ttlSeconds });
    } catch (error) {
      logger.warn(`[Cache] Set Error: ${key}`, { error: error.message });
    }
  },

  del: async (key) => {
    try {
      store.delete(key);
      logger.debug(`[Cache] Del: ${key}`);
    } catch (error) {
      logger.warn(`[Cache] Del Error: ${key}`, { error: error.message });
    }
  },

  clearPattern: async (pattern) => {
    try {
      let deletedCount = 0;
      for (const key of store.keys()) {
        if (matchesPattern(key, pattern)) {
          store.delete(key);
          deletedCount += 1;
        }
      }
      logger.debug(`[Cache] ClearPattern: ${pattern}`, { deleted: deletedCount });
      return deletedCount;
    } catch (error) {
      logger.warn(`[Cache] ClearPattern Error: ${pattern}`, { error: error.message });
      return 0;
    }
  },

  exists: async (key) => {
    const record = store.get(key);
    if (!record) return false;
    if (isExpired(record)) {
      store.delete(key);
      return false;
    }
    return true;
  },

  getOrSet: async (key, fetchFn, ttlSeconds = TTL.DEFAULT) => {
    try {
      const cached = await cache.get(key);
      if (cached !== null) {
        logger.debug(`[Cache] Hit: ${key}`);
        return cached;
      }

      logger.debug(`[Cache] Miss: ${key}`);
      const value = await fetchFn();
      if (value !== null && value !== undefined) {
        await cache.set(key, value, ttlSeconds);
      }
      return value;
    } catch (error) {
      logger.warn(`[Cache] GetOrSet Error: ${key}`, { error: error.message });
      return fetchFn();
    }
  },

  weather: {
    get: (lat, lon) => cache.get(`${PREFIXES.WEATHER}:${lat}:${lon}`),
    set: (lat, lon, data) => cache.set(`${PREFIXES.WEATHER}:${lat}:${lon}`, data, TTL.WEATHER),
    getForecast: (lat, lon) => cache.get(`${PREFIXES.WEATHER}:forecast:${lat}:${lon}`),
    setForecast: (lat, lon, data) => cache.set(`${PREFIXES.WEATHER}:forecast:${lat}:${lon}`, data, TTL.WEATHER_FORECAST),
    invalidate: (lat, lon) => cache.del(`${PREFIXES.WEATHER}:${lat}:${lon}`),
    invalidateAll: () => cache.clearPattern(`${PREFIXES.WEATHER}:*`)
  },

  parcelles: {
    getByUser: (userId) => cache.get(`${PREFIXES.PARCELLES}:user:${userId}`),
    setByUser: (userId, data) => cache.set(`${PREFIXES.PARCELLES}:user:${userId}`, data, TTL.PARCELLES),
    getById: (id) => cache.get(`${PREFIXES.PARCELLES}:${id}`),
    setById: (id, data) => cache.set(`${PREFIXES.PARCELLES}:${id}`, data, TTL.PARCELLES),
    invalidateUser: (userId) => cache.del(`${PREFIXES.PARCELLES}:user:${userId}`),
    invalidateById: (id) => cache.del(`${PREFIXES.PARCELLES}:${id}`),
    invalidateAll: () => cache.clearPattern(`${PREFIXES.PARCELLES}:*`)
  },

  sensors: {
    getData: (capteurId) => cache.get(`${PREFIXES.SENSORS}:${capteurId}`),
    setData: (capteurId, data) => cache.set(`${PREFIXES.SENSORS}:${capteurId}`, data, TTL.SENSORS),
    getByParcelle: (parcelleId) => cache.get(`${PREFIXES.SENSORS}:parcelle:${parcelleId}`),
    setByParcelle: (parcelleId, data) => cache.set(`${PREFIXES.SENSORS}:parcelle:${parcelleId}`, data, TTL.SENSORS),
    invalidate: (capteurId) => cache.del(`${PREFIXES.SENSORS}:${capteurId}`),
    invalidateAll: () => cache.clearPattern(`${PREFIXES.SENSORS}:*`)
  },

  marketplace: {
    getProducts: (page = 1, filters = '') => cache.get(`${PREFIXES.MARKETPLACE}:products:${page}:${filters}`),
    setProducts: (page, filters, data) => cache.set(`${PREFIXES.MARKETPLACE}:products:${page}:${filters}`, data, TTL.MARKETPLACE),
    getProduct: (id) => cache.get(`${PREFIXES.MARKETPLACE}:product:${id}`),
    setProduct: (id, data) => cache.set(`${PREFIXES.MARKETPLACE}:product:${id}`, data, TTL.MARKETPLACE),
    invalidateProduct: (id) => cache.del(`${PREFIXES.MARKETPLACE}:product:${id}`),
    invalidateAll: () => cache.clearPattern(`${PREFIXES.MARKETPLACE}:*`)
  },

  user: {
    getProfile: (userId) => cache.get(`${PREFIXES.USER}:profile:${userId}`),
    setProfile: (userId, data) => cache.set(`${PREFIXES.USER}:profile:${userId}`, data, TTL.USER_PROFILE),
    invalidateProfile: (userId) => cache.del(`${PREFIXES.USER}:profile:${userId}`)
  },

  regions: {
    getAll: () => cache.get(`${PREFIXES.REGIONS}:all`),
    setAll: (data) => cache.set(`${PREFIXES.REGIONS}:all`, data, TTL.REGIONS),
    getById: (id) => cache.get(`${PREFIXES.REGIONS}:${id}`),
    setById: (id, data) => cache.set(`${PREFIXES.REGIONS}:${id}`, data, TTL.REGIONS)
  },

  TTL,
  PREFIXES,

  getClient: () => null
};

module.exports = cache;
