/**
 * Configuration de la base de données MySQL
 * AgroSmart - Système Agricole Intelligent
 */

const mysql = require('mysql2/promise');
const winston = require('winston');

// Configuration du logger pour la DB
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

// Configuration du pool de connexions MySQL
const poolConfig = {
  host: process.env.DB_HOST || '127.0.0.1',
  port: parseInt(process.env.DB_PORT) || 3306,
  database: process.env.DB_NAME || 'agrismart_ci',
  user: process.env.DB_USER || 'agrismart',
  password: process.env.DB_PASSWORD,

  // Configuration du pool
  connectionLimit: 20,              // Nombre max de clients dans le pool
  waitForConnections: true,         // Attendre une connexion si le pool est plein
  queueLimit: 0,                    // Pas de limite sur la file d'attente
  enableKeepAlive: true,            // Maintenir les connexions actives
  keepAliveInitialDelay: 30000,     // Délai initial pour keep-alive

  // Timezone
  timezone: '+00:00',

  // Support des dates JavaScript natives
  dateStrings: false,

  // Character encoding
  charset: 'utf8mb4'
};

// Log de config DB en développement
if (process.env.NODE_ENV === 'development') {
  const logger = require('../utils/logger');
  logger.debug('DB Config', {
    host: poolConfig.host,
    port: poolConfig.port,
    database: poolConfig.database,
    user: poolConfig.user
  });
}

// Création du pool
const pool = mysql.createPool(poolConfig);

// Événements du pool (mysql2 ne supporte pas les événements comme pg, mais on peut logger)
logger.debug('Pool de connexions MySQL créé');

/**
 * Exécute une requête SQL
 * @param {string} text - Requête SQL
 * @param {Array} params - Paramètres de la requête
 * @returns {Promise} - Résultat de la requête
 */
const query = async (text, params) => {
  const start = Date.now();
  try {
    const [rows] = await pool.execute(text, params);
    const duration = Date.now() - start;

    logger.debug('Requête exécutée', {
      query: text.substring(0, 100),
      duration: `${duration}ms`,
      rows: Array.isArray(rows) ? rows.length : rows.affectedRows
    });

    // Retourner un format compatible avec l'ancien code pg
    return {
      rows: Array.isArray(rows) ? rows : [],
      rowCount: Array.isArray(rows) ? rows.length : rows.affectedRows,
      affectedRows: rows.affectedRows || 0,
      insertId: rows.insertId || null
    };
  } catch (error) {
    logger.error('Erreur requête SQL', {
      query: text.substring(0, 100),
      error: error.message
    });
    throw error;
  }
};

/**
 * Obtient une connexion du pool pour les transactions
 * @returns {Promise} - Connexion MySQL
 */
const getClient = async () => {
  const connection = await pool.getConnection();

  // Timeout pour éviter les connexions bloquées
  const timeout = setTimeout(() => {
    logger.error('Connexion MySQL bloquée, forçage de la libération');
    connection.release();
  }, 30000);

  // Surcharger la méthode release pour nettoyer le timeout
  const originalRelease = connection.release.bind(connection);
  connection.release = () => {
    clearTimeout(timeout);
    originalRelease();
  };

  return connection;
};

/**
 * Exécute une transaction
 * @param {Function} callback - Fonction contenant les opérations de transaction
 * @returns {Promise} - Résultat de la transaction
 */
const transaction = async (callback) => {
  const connection = await getClient();

  try {
    await connection.beginTransaction();
    const result = await callback(connection);
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

/**
 * Vérifie la connexion à la base de données
 * @returns {Promise<boolean>}
 */
const checkConnection = async () => {
  try {
    const result = await query('SELECT NOW() as current_time, DATABASE() as `database`');
    logger.info('Connexion MySQL établie', {
      database: result.rows[0].database,
      time: result.rows[0].current_time
    });
    return true;
  } catch (error) {
    logger.error('Échec connexion MySQL', { error: error.message });
    return false;
  }
};

/**
 * Ferme toutes les connexions du pool
 */
const closePool = async () => {
  await pool.end();
  logger.info('Pool de connexions MySQL fermé');
};

/**
 * Statistiques du pool de connexions
 * Note: mysql2 ne fournit pas les mêmes statistiques que pg
 */
const getPoolStats = () => {
  const poolState = pool.pool;
  return {
    totalCount: poolState ? poolState._allConnections.length : 0,
    idleCount: poolState ? poolState._freeConnections.length : 0,
    waitingCount: poolState ? poolState._connectionQueue.length : 0
  };
};

module.exports = {
  pool,
  query,
  getClient,
  transaction,
  checkConnection,
  closePool,
  getPoolStats
};
