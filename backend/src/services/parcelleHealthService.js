/**
 * Service de calcul de la santé d'une parcelle
 * Recalcule l'état de santé en fonction des dernières mesures de tous les capteurs
 * 
 * Logique:
 *  - CRITIQUE: au moins un capteur a une valeur critique (très hors seuils)
 *  - SURVEILLANCE: au moins un capteur est hors seuils (warning)
 *  - OPTIMAL: toutes les mesures sont dans les seuils normaux
 */

const prisma = require('../config/prisma');
const logger = require('../utils/logger');

// Seuils par type de capteur (NPK en mg/kg)
const THRESHOLDS = {
  NPK: {
    nitrogen:   { critiqueBas: 30, warningBas: 50, warningHaut: 200, critiqueHaut: 250 },
    phosphorus: { critiqueBas: 20, warningBas: 30, warningHaut: 100, critiqueHaut: 130 },
    potassium:  { critiqueBas: 100, warningBas: 150, warningHaut: 300, critiqueHaut: 350 },
  },
  HUMIDITE_SOL: {
    default: { critiqueBas: 15, warningBas: 25, warningHaut: 75, critiqueHaut: 85 },
  },
  HUMIDITE_TEMPERATURE_AMBIANTE: {
    default: { critiqueBas: 5, warningBas: 10, warningHaut: 40, critiqueHaut: 45 },
  },
  TEMPERATURE: {
    default: { critiqueBas: 5, warningBas: 10, warningHaut: 40, critiqueHaut: 45 },
  },
  PH: {
    default: { critiqueBas: 4.0, warningBas: 5.5, warningHaut: 7.5, critiqueHaut: 8.5 },
  },
};

/**
 * Évalue le niveau de santé d'une valeur par rapport aux seuils
 * @returns {'OPTIMAL'|'SURVEILLANCE'|'CRITIQUE'}
 */
function evaluateValue(value, thresholds) {
  if (value <= thresholds.critiqueBas || value >= thresholds.critiqueHaut) {
    return 'CRITIQUE';
  }
  if (value <= thresholds.warningBas || value >= thresholds.warningHaut) {
    return 'SURVEILLANCE';
  }
  return 'OPTIMAL';
}

/**
 * Retourne le pire niveau entre deux niveaux de santé
 */
function worstHealth(current, newLevel) {
  const order = { OPTIMAL: 0, SURVEILLANCE: 1, CRITIQUE: 2 };
  return order[newLevel] > order[current] ? newLevel : current;
}

/**
 * Recalcule la santé d'une parcelle à partir des dernières mesures
 * @param {string} parcelleId 
 * @returns {Promise<string>} Le nouveau niveau de santé
 */
async function recalculateParcelleHealth(parcelleId) {
  try {
    // Récupérer tous les capteurs ACTIFS de la parcelle avec leur dernière mesure
    const capteurs = await prisma.capteur.findMany({
      where: {
        parcelleId: parcelleId,
        statut: 'ACTIF'
      },
      select: {
        id: true,
        type: true,
        seuilMin: true,
        seuilMax: true,
        mesures: {
          take: 1,
          orderBy: { timestamp: 'desc' },
          select: { valeur: true, timestamp: true }
        }
      }
    });

    if (capteurs.length === 0) {
      // Pas de capteur actif → garder OPTIMAL par défaut
      return 'OPTIMAL';
    }

    let overallHealth = 'OPTIMAL';

    for (const capteur of capteurs) {
      if (capteur.mesures.length === 0) continue;

      const valeur = parseFloat(capteur.mesures[0].valeur);
      if (isNaN(valeur)) continue;

      const typeKey = capteur.type?.toUpperCase();

      // Cas spécial NPK: la valeur JSON peut contenir N, P, K
      if (typeKey === 'NPK') {
        // Pour les capteurs NPK, on vérifie individuellement les éléments
        // La valeur peut être un JSON {N: x, P: y, K: z} ou une valeur simple
        let npkValues = {};
        try {
          const parsed = JSON.parse(capteur.mesures[0].valeur);
          if (typeof parsed === 'object') {
            npkValues = parsed;
          }
        } catch {
          // Valeur simple, utiliser comme N par défaut
          npkValues = { N: valeur };
        }

        // Vérifier chaque élément NPK
        for (const [element, val] of Object.entries(npkValues)) {
          const numVal = parseFloat(val);
          if (isNaN(numVal)) continue;

          let thresholdKey;
          const elemUpper = element.toUpperCase();
          if (elemUpper === 'N' || elemUpper === 'NITROGEN' || elemUpper === 'AZOTE') {
            thresholdKey = 'nitrogen';
          } else if (elemUpper === 'P' || elemUpper === 'PHOSPHORUS' || elemUpper === 'PHOSPHORE') {
            thresholdKey = 'phosphorus';
          } else if (elemUpper === 'K' || elemUpper === 'POTASSIUM') {
            thresholdKey = 'potassium';
          }

          if (thresholdKey && THRESHOLDS.NPK[thresholdKey]) {
            const level = evaluateValue(numVal, THRESHOLDS.NPK[thresholdKey]);
            overallHealth = worstHealth(overallHealth, level);
          }
        }

        // Si valeur simple (pas JSON), vérifier en tant que N
        if (Object.keys(npkValues).length === 1 && npkValues.N !== undefined) {
          const level = evaluateValue(npkValues.N, THRESHOLDS.NPK.nitrogen);
          overallHealth = worstHealth(overallHealth, level);
        }

        continue;
      }

      // Autres types de capteurs: utiliser les seuils du capteur en DB ou les seuils par défaut
      const capteurSeuilMin = capteur.seuilMin ? parseFloat(capteur.seuilMin) : null;
      const capteurSeuilMax = capteur.seuilMax ? parseFloat(capteur.seuilMax) : null;

      if (capteurSeuilMin !== null && capteurSeuilMax !== null) {
        // Utiliser les seuils configurés sur le capteur
        const range = capteurSeuilMax - capteurSeuilMin;
        const margin = range * 0.15; // 15% de marge pour warning

        const thresholds = {
          critiqueBas: capteurSeuilMin - margin,
          warningBas: capteurSeuilMin,
          warningHaut: capteurSeuilMax,
          critiqueHaut: capteurSeuilMax + margin,
        };

        const level = evaluateValue(valeur, thresholds);
        overallHealth = worstHealth(overallHealth, level);
      } else if (THRESHOLDS[typeKey]?.default) {
        // Utiliser les seuils par défaut du type
        const level = evaluateValue(valeur, THRESHOLDS[typeKey].default);
        overallHealth = worstHealth(overallHealth, level);
      }
    }

    // Mettre à jour la parcelle en base
    await prisma.parcelle.update({
      where: { id: parcelleId },
      data: { sante: overallHealth }
    });

    logger.info(`Santé parcelle ${parcelleId} recalculée: ${overallHealth}`);
    return overallHealth;

  } catch (error) {
    logger.error('Erreur recalcul santé parcelle', { 
      parcelleId, 
      error: error.message 
    });
    // Ne pas propager l'erreur pour ne pas bloquer le flux principal
    return null;
  }
}

/**
 * Recalcule la santé d'une parcelle à partir d'un capteur
 * Pratique quand on connaît le capteurId mais pas la parcelleId
 * @param {string} capteurId 
 */
async function recalculateFromCapteur(capteurId) {
  try {
    const capteur = await prisma.capteur.findUnique({
      where: { id: capteurId },
      select: { parcelleId: true, stationId: true }
    });

    if (!capteur) return null;

    let parcelleId = capteur.parcelleId;

    // Si le capteur est lié via une station
    if (!parcelleId && capteur.stationId) {
      const station = await prisma.station.findUnique({
        where: { id: capteur.stationId },
        select: { parcelleId: true }
      });
      parcelleId = station?.parcelleId;
    }

    if (!parcelleId) return null;

    return await recalculateParcelleHealth(parcelleId);
  } catch (error) {
    logger.error('Erreur recalcul santé depuis capteur', { 
      capteurId, 
      error: error.message 
    });
    return null;
  }
}

module.exports = {
  recalculateParcelleHealth,
  recalculateFromCapteur,
  THRESHOLDS
};
