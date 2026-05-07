/**
 * Service de traitement des mesures IoT
 * AgroSmart fonctionne en mode synchrone sans file externe.
 */
const logger = require('../utils/logger');

/**
 * Ajouter une mesure pour traitement immédiat
 * @param {Object} data Données de la mesure (capteur_id, valeur, unite, timestamp)
 */
exports.addJob = async (data) => {
    try {
        logger.debug('[Queue] Processing measure synchronously', { data });
        const { processMeasure } = require('../workers/sensorWorker');
        return processMeasure({ id: `sync-${Date.now()}`, data });
    } catch (error) {
        logger.error('Échec traitement mesure', { error: error.message });
        throw error;
    }
};

/**
 * Obtenir le client de file (aucun en mode synchrone)
 */
exports.getQueue = () => null;
