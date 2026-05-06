/**
 * Client Redis optionnel — utilisé pour rate-limit, brute-force et cache.
 * Si REDIS_URL n'est pas défini, les modules tombent en fallback mémoire.
 */

const Redis = require('ioredis');
const logger = require('../utils/logger');

let redisClient = null;

if (process.env.REDIS_URL) {
  redisClient = new Redis(process.env.REDIS_URL, {
    lazyConnect: true,
    maxRetriesPerRequest: 1,
    retryStrategy: (times) => (times > 3 ? null : Math.min(times * 200, 2000)),
    enableOfflineQueue: false,
  });

  redisClient.on('connect', () => logger.info('Redis: connecté'));
  redisClient.on('error', (err) => logger.warn('Redis: erreur connexion', { message: err.message }));
  redisClient.on('close', () => logger.warn('Redis: connexion fermée'));

  redisClient.connect().catch((err) =>
    logger.warn('Redis: impossible de se connecter au démarrage', { message: err.message })
  );
} else {
  logger.info('Redis: REDIS_URL non défini — rate-limit et brute-force en mémoire (non recommandé en prod)');
}

module.exports = redisClient;
