/**
 * Traitement des mesures IoT
 * Fournit la fonction processMeasure pour un traitement synchrone.
 */
const prisma = require('../config/prisma');
const logger = require('../utils/logger');
const alertesService = require('../services/alertesService');
const parcelleHealthService = require('../services/parcelleHealthService');

/**
 * Traiter un job de mesure
 * @param {Object} job Job local
 */
const processMeasure = async (job) => {
    // Support both direct ID (HTTP) and device_code (MQTT)
    let { capteur_id, valeur, unite, mesure_at, batch, device_code, values } = job.data;

    try {
        const timestamp = mesure_at ? new Date(mesure_at) : new Date();

        // Cas 1: Payloads MQTT { device_code, values: { type: val, ... } }
        if (device_code && values) {
            // Check if Station code exists. Schema Station model must have 'code'.
            // If Schema doesn't have 'code', we might need to use ID or fix schema.
            // Assuming 'code' exists or we need to find by it.
            // If schema `Station` uses `device_id` or similar? 
            // Let's assume 'code' field exists for now based on legacy SQL.
            const station = await prisma.station.findUnique({
                where: { code: device_code },
                include: { parcelle: true }
            });

            if (!station) {
                logger.warn(`Station introuvable pour code ${device_code}`);
                return { status: 'ignored', reason: 'station_not_found' };
            }

            const results = [];

            // Mapping des clés MQTT vers les valeurs d'enum CapteurType (Prisma)
            // Un capteur HUMIDITE_TEMPERATURE_AMBIANTE (ex: DHT22) mesure à la fois
            // l'humidité ambiante ET la température — les deux clés pointent vers ce type.
            // HUMIDITE_SOL est un capteur séparé (sonde de sol).
            const MQTT_TYPE_MAP = {
                humidity: 'HUMIDITE_TEMPERATURE_AMBIANTE',
                temperature: 'HUMIDITE_TEMPERATURE_AMBIANTE',
                soil_moisture: 'HUMIDITE_SOL',
                npk: 'NPK',
                uv: 'UV',
                wind_direction: 'DIRECTION_VENT',
                transpiration: 'TRANSPIRATION_PLANTE',
            };

            for (const [type, val] of Object.entries(values)) {
                const enumType = MQTT_TYPE_MAP[type] || type.toUpperCase();

                const sensor = await prisma.capteur.findFirst({
                    where: {
                        stationId: station.id,
                        type: enumType
                        // If findFirst fails due to type mismatch (e.g. 'humidite_sol' vs 'HUMIDITE_SOL'), we might need a mapping.
                    }
                });

                if (sensor) {
                    await prisma.mesure.create({
                        data: {
                            capteurId: sensor.id,
                            valeur: String(val),
                            unite: 'unit', // Legacy used 'unit'.
                            timestamp: timestamp
                        }
                    });

                    try {
                        await alertesService.checkThresholds(sensor.id, val);
                    } catch (alertErr) {
                        logger.warn('Erreur alerte MQTT', { error: alertErr.message });
                    }

                    results.push(sensor.id);
                }
            }

            // Recalculer la santé de la parcelle après ingestion MQTT
            if (station.parcelleId) {
                try {
                    await parcelleHealthService.recalculateParcelleHealth(station.parcelleId);
                } catch (healthErr) {
                    logger.warn('Erreur recalcul santé parcelle (MQTT)', { error: healthErr.message });
                }
            }

            return { status: 'success', processed: results.length };
        }

        // Cas 2: Payload HTTP standard (capteur_id unique)
        const capteur = await prisma.capteur.findUnique({
            where: { id: capteur_id },
            include: { station: true }
        });

        if (!capteur) {
            throw new Error(`Capteur ${capteur_id} non trouvé`);
        }

        if (capteur.statut !== 'ACTIF' && capteur.statut !== 'MAINTENANCE') {
            logger.warn(`Mesure ignorée pour capteur inactif`, { capteur_id, status: capteur.statut });
            return { status: 'ignored', reason: 'sensor_inactive' };
        }

        const result = await prisma.mesure.create({
            data: {
                capteurId: capteur_id,
                valeur: String(valeur),
                unite: unite,
                timestamp: timestamp
            }
        });

        try {
            if (!batch) {
                await alertesService.checkThresholds(capteur_id, valeur);
            }
        } catch (alertErr) {
            logger.warn('Erreur vérification alertes dans worker', { error: alertErr.message, capteur_id });
        }

        // Recalculer la santé de la parcelle après ingestion HTTP
        try {
            await parcelleHealthService.recalculateFromCapteur(capteur_id);
        } catch (healthErr) {
            logger.warn('Erreur recalcul santé parcelle (HTTP)', { error: healthErr.message, capteur_id });
        }

        return {
            status: 'success',
            id: result.id
        };

    } catch (error) {
        logger.error('Erreur traitement mesure worker', { error: error.message, jobData: job.data });
        throw error;
    }
};

/**
 * Initialiser le worker
 * Le mode file externe est retiré: retourne null.
 */
const initWorker = () => {
    logger.info('Worker IoT externe désactivé: mode synchrone actif.');
    return null;
};

module.exports = { initWorker, processMeasure };
