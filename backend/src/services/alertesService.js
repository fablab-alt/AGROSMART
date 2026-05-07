/**
 * Service de gestion des alertes automatiques
 * AgroSmart - Système Agricole Intelligent
 */

const prisma = require('../config/prisma');
const config = require('../config');
const logger = require('../utils/logger');
const notificationService = require('./notificationService');

/**
 * Seuils d'alerte par type de capteur
 */
const SEUILS = config.alertThresholds;

/**
 * Vérifier les seuils et créer une alerte si nécessaire
 */
/**
 * Vérifier les seuils et créer une alerte si nécessaire
 */
exports.checkThresholds = async (capteurId, valeur) => {
  try {
    // Récupérer les informations du capteur
    const capteur = await prisma.capteur.findUnique({
      where: { id: capteurId },
      include: {
        station: {
          include: {
            parcelle: {
              select: {
                id: true,
                nom: true,
                userId: true // Check field name in User model vs Parcelle model relation
                // Parcelle has userId.
              }
            }
          }
        }
      }
    });

    if (!capteur) return null;

    const seuils = SEUILS[capteur.type];
    if (!seuils) return null;

    // Seuils personnalisés du capteur ou de la parcelle
    // Assuming config is JSON field in Prisma or we parse it if string
    // Schema likely has config as Json?
    const config = capteur.config || {};
    const customSeuils = config.seuils || {};
    const min = customSeuils.min ?? seuils.min;
    const max = customSeuils.max ?? seuils.max;
    const criticalMin = customSeuils.criticalMin ?? seuils.criticalMin;
    const criticalMax = customSeuils.criticalMax ?? seuils.criticalMax;

    let alerte = null;
    const stationNom = capteur.station?.nom || 'Inconnue';

    // Vérifier les seuils critiques
    if (valeur <= criticalMin || valeur >= criticalMax) {
      alerte = {
        niveau: 'critical',
        type: 'capteur',
        titre: `Valeur critique: ${capteur.type}`,
        message: this.generateAlertMessage(capteur.type, valeur, 'critical', stationNom)
      };
    }
    // Vérifier les seuils d'avertissement
    else if (valeur <= min || valeur >= max) {
      alerte = {
        niveau: 'warning',
        type: 'capteur',
        titre: `Attention: ${capteur.type}`,
        message: this.generateAlertMessage(capteur.type, valeur, 'warning', stationNom)
      };
    }

    if (alerte) {
      // Vérifier si une alerte similaire n'a pas été créée récemment
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
      const recentAlert = await prisma.alerte.findFirst({
        where: {
          capteurId: capteurId,
          niveau: alerte.niveau,
          resolue: false,
          createdAt: { gt: oneHourAgo }
        }
      });

      if (recentAlert) {
        logger.debug('Alerte similaire récente existe', { capteurId, niveau: alerte.niveau });
        return null;
      }

      // Créer l'alerte
      // We need userId from Parcelle.
      const userId = capteur.station?.parcelle?.userId;
      const parcelleId = capteur.station?.parcelleId;

      const createdAlerte = await prisma.alerte.create({
        data: {
          userId,
          parcelleId,
          capteurId,
          type: alerte.type,
          niveau: alerte.niveau,
          titre: alerte.titre,
          message: alerte.message,
          source: 'automatique'
        }
      });

      // Envoyer les notifications
      try {
        await notificationService.sendAlert(userId, {
          ...createdAlerte,
          parcelle_nom: capteur.station?.parcelle?.nom
        });
      } catch (notifError) {
        logger.warn('Échec notification alerte', { error: notifError.message });
      }

      logger.info('Alerte automatique créée', {
        alerteId: createdAlerte.id,
        capteurId,
        niveau: alerte.niveau
      });

      return createdAlerte;
    }

    return null;
  } catch (error) {
    logger.error('Erreur vérification seuils', { capteurId, error: error.message });
    throw error;
  }
};

/**
 * Générer le message d'alerte
 */
exports.generateAlertMessage = (type, valeur, niveau, stationNom) => {
  const unites = {
    temperature: '°C',
    humidite_sol: '%',
    humidite_air: '%',
    luminosite: 'lux',
    pluviometrie: 'mm',
    ph_sol: '',
    niveau_eau: 'cm'
  };

  const labels = {
    temperature: 'Température',
    humidite_sol: 'Humidité du sol',
    humidite_air: 'Humidité de l\'air',
    luminosite: 'Luminosité',
    pluviometrie: 'Pluviométrie',
    ph_sol: 'pH du sol',
    niveau_eau: 'Niveau d\'eau'
  };

  const unite = unites[type] || '';
  const label = labels[type] || type;

  if (niveau === 'critical') {
    return `⚠️ ATTENTION: ${label} a atteint un niveau critique (${valeur}${unite}) sur la station ${stationNom}. Action immédiate requise.`;
  } else {
    return `${label} hors des limites normales (${valeur}${unite}) sur la station ${stationNom}. Surveillance recommandée.`;
  }
};

/**
 * Vérifier les capteurs hors ligne
 */
exports.checkOfflineSensors = async () => {
  try {
    const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);

    // Fetch sensors that are active but haven't sent data, AND exclude those with recent alerts
    // Using simple approach: fetch candidates then filter manually or use multiple queries.
    // Prisma complex negation filters can be heavy.

    // Find sensors offline
    const offlineSensors = await prisma.capteur.findMany({
      where: {
        statut: 'ACTIF',
        OR: [
          { derniereMesure: null },
          { derniereMesure: { lt: thirtyMinutesAgo } }
        ]
      },
      include: {
        station: {
          include: {
            parcelle: {
              select: { nom: true, userId: true }
            }
          }
        },
        alertes: {
          where: {
            type: 'systeme',
            resolue: false,
            createdAt: { gt: twoHoursAgo }
          }
        }
      }
    });

    let count = 0;

    for (const capteur of offlineSensors) {
      if (capteur.alertes.length > 0) continue; // Already alerted recently

      const message = `Le capteur ${capteur.type} sur la station ${capteur.station?.nom} ne répond plus depuis plus de 30 minutes.`;

      const alerte = await prisma.alerte.create({
        data: {
          userId: capteur.station?.parcelle?.userId,
          parcelleId: capteur.station?.parcelleId,
          capteurId: capteur.id,
          type: 'systeme',
          niveau: 'warning',
          titre: `Capteur hors ligne: ${capteur.type}`,
          message: message,
          source: 'automatique'
        }
      });

      // Notifier
      try {
        await notificationService.sendAlert(capteur.station?.parcelle?.userId, {
          ...alerte,
          parcelle_nom: capteur.station?.parcelle?.nom
        });
      } catch (e) {
        // ignore
      }
      count++;
    }

    if (count > 0) {
      logger.info('Capteurs hors ligne détectés', { count });
    }

    return count;
  } catch (error) {
    logger.error('Erreur vérification capteurs hors ligne', { error: error.message });
    throw error;
  }
};

/**
 * Analyser les tendances et anticiper les problèmes
 */
exports.analyzeTrends = async (parcelleId) => {
  try {
    // Analyser les tendances sur 24h
    // Use raw query for aggregations
    const trends = await prisma.$queryRaw`
       SELECT c.type,
              AVG(CAST(m.valeur AS DECIMAL)) as moyenne,
              MIN(CAST(m.valeur AS DECIMAL)) as min,
              MAX(CAST(m.valeur AS DECIMAL)) as max,
              STDDEV(CAST(m.valeur AS DECIMAL)) as ecart_type,
              (SELECT valeur FROM mesures WHERE capteur_id = c.id ORDER BY timestamp DESC LIMIT 1) as derniere_valeur
       FROM capteurs c
       JOIN stations s ON c.station_id = s.id
       JOIN mesures m ON c.id = m.capteur_id
       WHERE s.parcelle_id = ${parcelleId}
         AND m.timestamp > NOW() - INTERVAL '24 hours'
       GROUP BY c.id, c.type
    `;

    const alertes = [];

    for (const trend of trends) {
      const seuils = SEUILS[trend.type];
      if (!seuils) continue;

      const derniereValeur = parseFloat(trend.derniere_valeur);
      const moyenne = parseFloat(trend.moyenne);

      // Détecter les tendances dangereuses
      if (derniereValeur && moyenne) {
        const variation = ((derniereValeur - moyenne) / moyenne) * 100;

        // Si la valeur actuelle est 20% supérieure à la moyenne et proche du seuil max
        if (variation > 20 && derniereValeur > seuils.max * 0.9) {
          alertes.push({
            type: trend.type,
            niveau: 'warning',
            message: `Tendance à la hausse détectée pour ${trend.type}. Valeur actuelle: ${derniereValeur}, Moyenne 24h: ${moyenne.toFixed(2)}`
          });
        }
      }
    }

    return alertes;
  } catch (error) {
    logger.error('Erreur analyse tendances', { parcelleId, error: error.message });
    throw error;
  }
};

module.exports = exports;
