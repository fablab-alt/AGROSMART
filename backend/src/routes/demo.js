/**
 * Routes publiques de démonstration
 * AgroSmart - Système Agricole Intelligent
 *
 * Ces routes sont accessibles SANS authentification
 * et fournissent des données de démonstration pour le mode visiteur
 */

const express = require('express');
const router = express.Router();

/**
 * @route   GET /api/demo/parcelles
 * @desc    Données de démonstration des parcelles
 * @access  Public (pas d'auth requise)
 */
router.get('/parcelles', (req, res) => {
  try {
    const demoParcels = [
      {
        id: '1',
        nom: 'Parcelle Cacao Nord',
        superficie: 3.5,
        latitude: 5.3599,
        longitude: -4.0083,
        culture: 'Cacao',
        humidite: 65,
        temperature: 28,
        ph: 6.5,
        status: 'optimal',
        sante_globale: 92,
      },
      {
        id: '2',
        nom: 'Parcelle Café Centre',
        superficie: 2.1,
        latitude: 5.3600,
        longitude: -4.0081,
        culture: 'Café',
        humidite: 42,
        temperature: 31,
        ph: 6.0,
        status: 'alerte',
        sante_globale: 68,
      },
      {
        id: '3',
        nom: 'Parcelle Plantain Est',
        superficie: 1.8,
        latitude: 5.3598,
        longitude: -4.0085,
        culture: 'Plantain',
        humidite: 78,
        temperature: 26,
        ph: 7.2,
        status: 'optimal',
        sante_globale: 88,
      },
    ];

    res.json({
      success: true,
      message: 'Données de démonstration des parcelles',
      data: demoParcels,
      note: 'Ceci est une démonstration. Connectez-vous pour accéder à vos vraies parcelles.',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des données de démonstration',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/demo/alertes
 * @desc    Alertes de démonstration
 * @access  Public
 */
router.get('/alertes', (req, res) => {
  try {
    const demoAlerts = [
      {
        id: '1',
        type: 'irrigation',
        titre: 'Stress hydrique détecté',
        description: 'Humidité faible sur Parcelle Café Centre (42%). Arrosage recommandé.',
        severite: 'moyen',
        parcelleId: '2',
        culture: 'Café',
        createdAt: new Date(Date.now() - 2 * 3600000).toISOString(),
      },
      {
        id: '2',
        type: 'maladie',
        titre: 'Feuille noire possible',
        description: 'Conditions météo favorables détectées. Inspection des feuilles recommandée.',
        severite: 'moyen',
        parcelleId: '1',
        culture: 'Cacao',
        createdAt: new Date(Date.now() - 4 * 3600000).toISOString(),
      },
      {
        id: '3',
        type: 'temperature',
        titre: 'Température élevée',
        description: 'Température > 30°C sur Parcelle Café. Stress thermique possible.',
        severite: 'faible',
        parcelleId: '2',
        culture: 'Café',
        createdAt: new Date(Date.now() - 1 * 3600000).toISOString(),
      },
    ];

    res.json({
      success: true,
      message: 'Alertes de démonstration',
      data: demoAlerts,
      count: demoAlerts.length,
      note: 'Ceci est une démonstration. Inscrivez-vous pour recevoir des alertes sur vos parcelles.',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des alertes de démonstration',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/demo/recommandations
 * @desc    Recommandations de démonstration
 * @access  Public
 */
router.get('/recommandations', (req, res) => {
  try {
    const demoRecommendations = [
      {
        id: '1',
        titre: 'Arrosage du Café',
        description: 'Arrosez immédiatement la Parcelle Café Centre. L\'humidité du sol est passée sous le seuil critique de 45%.',
        type: 'urgent',
        priorite: 'élevée',
        culture: 'Café',
        action: 'Arroser',
        estimatedTime: 1,
        potentialSaving: 5000,
        parcelleId: '2',
      },
      {
        id: '2',
        titre: 'Application de fertilisant',
        description: 'Il est temps d\'appliquer du fertilisant NPK sur votre parcelle Cacao. Cela augmentera le rendement de 15-20%.',
        type: 'conseil',
        priorite: 'moyenne',
        culture: 'Cacao',
        action: 'Fertiliser',
        estimatedTime: 7,
        potentialSaving: 12000,
        parcelleId: '1',
      },
      {
        id: '3',
        titre: 'Surveillance phytosanitaire',
        description: 'Conditions météo favorables aux maladies. Inspectez quotidiennement vos parcelles pour détecter les symptômes.',
        type: 'prévention',
        priorite: 'moyenne',
        culture: 'Tous',
        action: 'Inspecter',
        estimatedTime: 2,
        potentialSaving: 8000,
        parcelleId: null,
      },
    ];

    res.json({
      success: true,
      message: 'Recommandations de démonstration',
      data: demoRecommendations,
      count: demoRecommendations.length,
      note: 'Ceci est une démonstration. Nos recommandations IA deviennent plus précises après connexion.',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des recommandations de démonstration',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/demo/stats
 * @desc    Statistiques globales de démonstration
 * @access  Public
 */
router.get('/stats', (req, res) => {
  try {
    const demoStats = {
      platformStats: {
        totalFarmers: 5247,
        totalHectares: 51230,
        averageYield: '28.5 tonnes/ha',
        diseasePrevention: '94.3%',
        waterSavings: '35%',
        incomeIncrease: '28%',
      },
      userDemoData: {
        totalParcels: 3,
        activeSensors: 8,
        activeAlerts: 3,
        healthScore: 82.7,
        estimatedProduction: '12.5 tonnes',
      },
      regionData: {
        region: 'Abidjan, Côte d\'Ivoire',
        climate: 'Tropical humide',
        mainCrops: ['Cacao', 'Café', 'Plantain'],
        season: 'Saison des pluies',
        averageHumidity: 75,
        averageTemperature: 27,
      },
    };

    res.json({
      success: true,
      message: 'Statistiques de démonstration',
      data: demoStats,
      note: 'Ceci est une démonstration avec données simulées.',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des statistiques de démonstration',
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/demo/features
 * @desc    Liste des fonctionnalités principales
 * @access  Public
 */
router.get('/features', (req, res) => {
  try {
    const features = [
      {
        id: 'realtime-monitoring',
        name: 'Suivi en temps réel',
        description: 'Consultez instantanément l\'humidité, température, pH et nutriments de vos sols',
        icon: 'droplets',
        enabled: true,
      },
      {
        id: 'weather-forecast',
        name: 'Prévisions météo',
        description: 'Météo hyperlocale sur 10 jours avec alertes pour planifier vos activités',
        icon: 'cloud',
        enabled: true,
      },
      {
        id: 'smart-alerts',
        name: 'Alertes intelligentes',
        description: 'Notifications SMS et WhatsApp en cas de stress hydrique ou détection de maladies',
        icon: 'bell',
        enabled: true,
      },
      {
        id: 'ai-analysis',
        name: 'Analyse IA',
        description: 'Détection automatique de 50+ maladies avec 94% de précision',
        icon: 'brain',
        enabled: true,
      },
      {
        id: 'marketplace',
        name: 'Marketplace',
        description: 'Achetez et vendez semences, engrais et équipements directement depuis l\'app',
        icon: 'shopping-cart',
        enabled: true,
      },
      {
        id: 'training',
        name: 'Formations',
        description: 'Accédez à des tutoriels vidéo et fiches pratiques pour améliorer vos techniques',
        icon: 'graduation-cap',
        enabled: true,
      },
      {
        id: 'community',
        name: 'Communauté',
        description: 'Échangez avec d\'autres agriculteurs, partagez conseils et signalements',
        icon: 'users',
        enabled: true,
      },
      {
        id: 'economic-tracking',
        name: 'Suivi économique',
        description: 'Calculez votre ROI, économies d\'eau et réduction d\'intrants en temps réel',
        icon: 'trending-up',
        enabled: true,
      },
      {
        id: 'multiplatform',
        name: 'Multiplateforme',
        description: 'Disponible sur Android, iOS et web. Interface en français et langues locales',
        icon: 'smartphone',
        enabled: true,
      },
    ];

    res.json({
      success: true,
      message: 'Fonctionnalités disponibles',
      data: features,
      total: features.length,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des fonctionnalités',
      error: error.message,
    });
  }
});

module.exports = router;
