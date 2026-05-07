/**
 * Service de Prédiction et d'Analyse IA
 * Gère les prédictions de rendement et les cartes de chaleur des ravageurs
 */

const prisma = require('../config/prisma');
const logger = require('../utils/logger');

/**
 * Générer les données pour la heatmap des ravageurs
 * @param {string} regionId - ID de la région (optionnel)
 * @returns {Promise<Array>} Liste des points chauds
 */
exports.getPestHeatmapData = async (regionId) => {
  try {
    // Dans un cas réel, on filtrerait par région géographique
    // Ici, on simule ou on récupère les diagnostics récents positifs
    // On suppose que le modèle Diagnostic a 'location' (lat, lon) et 'result'

    /* 
    Schema Diagnostic supposé:
    - location: Json { lat, lng }
    - maladie: String (Nom de la maladie détectée)
    - confidence: Float
    - createdAt: DateTime
    */

    const oneMonthAgo = new Date();
    oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);

    const diagnostics = await prisma.diagnostic.findMany({
      where: {
        createdAt: { gt: oneMonthAgo },
        // On ne prend que ce qui a été détecté avec une forte confiance
        scoreConfiance: { gt: 0.7 },
        diseaseName: { not: null }
      },
      select: {
        diseaseName: true,
        localisation: true, // Suppose stored as string "lat,lon" or JSON
        createdAt: true
      }
    });

    // Transformer en format heatmap
    // Si localisation est "lat,lon"
    const points = diagnostics
      .filter(d => d.localisation && d.localisation.includes(','))
      .map(d => {
        const [lat, lng] = d.localisation.split(',').map(s => parseFloat(s.trim()));
        return {
          lat,
          lng,
          intensity: 1.0, // Base intensity
          disease: d.diseaseName
        };
      });

    return points;
  } catch (error) {
    logger.error('Erreur récupération heatmap', { error: error.message });
    throw error;
  }
};

/**
 * Prédire le rendement futur à partir des données historiques réelles
 */
exports.predictYield = async (parcelleId, dateRecolte) => {
  const history = await prisma.performanceParcelle.findMany({
    where: { parcelleId },
    orderBy: { annee: 'desc' },
    take: 5,
    select: {
      rendementMoyen: true,
      scoreQualiteSol: true,
      meilleurePratique: true,
      annee: true
    }
  });

  if (!history.length) {
    throw new Error('Aucune donnée historique disponible pour prédire le rendement de cette parcelle');
  }

  const values = history
    .map((item) => Number(item.rendementMoyen))
    .filter((value) => Number.isFinite(value));

  if (!values.length) {
    throw new Error('Données de rendement insuffisantes pour la prédiction');
  }

  const averageYield = values.reduce((sum, value) => sum + value, 0) / values.length;
  const confidence = Math.min(0.95, 0.55 + values.length * 0.08);
  const factors = history
    .map((item) => item.meilleurePratique)
    .filter(Boolean)
    .slice(0, 3);

  return {
    estime: Number(averageYield.toFixed(2)),
    confiance: Number(confidence.toFixed(2)),
    facteurs: factors.length ? factors : ['Basé sur historique des rendements']
  };
};
