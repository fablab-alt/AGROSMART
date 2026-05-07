/**
 * Contrôleur Chatbot IA Assistant Vocal
 * AgroSmart - Backend
 * 
 * Ce contrôleur gère l'assistant vocal multilingue capable de:
 * - Répondre aux questions agricoles
 * - Exécuter des actions dans l'application
 * - Supporter les langues locales ivoiriennes
 * - Fournir des conseils personnalisés
 */

const { PrismaClient } = require('@prisma/client');
const logger = require('../utils/logger');
const cache = require('../utils/cache');

const prisma = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });

/**
 * Langues supportées avec leurs configurations
 */
const SUPPORTED_LANGUAGES = {
  fr: {
    code: 'fr',
    name: 'Français',
    nativeName: 'Français',
    ttsSupported: true,
    sttSupported: true,
    region: 'Côte d\'Ivoire'
  },
  bci: {
    code: 'bci',
    name: 'Baoulé',
    nativeName: 'Baoulé',
    ttsSupported: false,
    sttSupported: false,
    region: 'Centre (Yamoussoukro, Bouaké)'
  },
  dyu: {
    code: 'dyu',
    name: 'Dioula',
    nativeName: 'Julakan',
    ttsSupported: false,
    sttSupported: false,
    region: 'Nord et Ouest'
  },
  sev: {
    code: 'sev',
    name: 'Sénoufo',
    nativeName: 'Sénoufo',
    ttsSupported: false,
    sttSupported: false,
    region: 'Nord (Korhogo)'
  },
  bev: {
    code: 'bev',
    name: 'Bété',
    nativeName: 'Bété',
    ttsSupported: false,
    sttSupported: false,
    region: 'Ouest (Daloa, Gagnoa)'
  },
  goa: {
    code: 'goa',
    name: 'Gouro',
    nativeName: 'Gouro',
    ttsSupported: false,
    sttSupported: false,
    region: 'Centre-Ouest'
  },
  ati: {
    code: 'ati',
    name: 'Attié',
    nativeName: 'Attié',
    ttsSupported: false,
    sttSupported: false,
    region: 'Sud (Adzopé)'
  }
};

/**
 * Actions disponibles pour l'assistant
 */
const AVAILABLE_ACTIONS = {
  // Navigation
  navigate: {
    name: 'Naviguer',
    description: 'Aller vers une page de l\'application',
    params: ['destination'],
    examples: ['Amène-moi aux parcelles', 'Ouvre le marketplace', 'Va aux alertes']
  },
  
  // Parcelles
  create_parcelle: {
    name: 'Créer une parcelle',
    description: 'Créer une nouvelle parcelle',
    params: ['nom', 'superficie', 'culture'],
    examples: ['Crée une parcelle de 2 hectares de cacao', 'Ajoute un champ d\'igname']
  },
  list_parcelles: {
    name: 'Lister les parcelles',
    description: 'Voir toutes vos parcelles',
    params: [],
    examples: ['Montre mes parcelles', 'Quelles sont mes parcelles?']
  },
  parcelle_status: {
    name: 'État d\'une parcelle',
    description: 'Vérifier l\'état d\'une parcelle',
    params: ['parcelle_id'],
    examples: ['Comment va ma parcelle de cacao?', 'État du champ Nord']
  },
  
  // Météo
  check_weather: {
    name: 'Consulter la météo',
    description: 'Obtenir les prévisions météo',
    params: ['location'],
    examples: ['Quel temps fait-il?', 'Va-t-il pleuvoir demain?', 'Météo à Korhogo']
  },
  
  // Diagnostic
  diagnose: {
    name: 'Diagnostic de maladie',
    description: 'Lancer un diagnostic de maladie',
    params: ['parcelle_id'],
    examples: ['Mes feuilles sont jaunes', 'Diagnostic de ma parcelle', 'Analyse cette plante']
  },
  
  // Marketplace
  marketplace_search: {
    name: 'Rechercher sur le marché',
    description: 'Chercher des produits sur le marketplace',
    params: ['query', 'categorie'],
    examples: ['Trouve des engrais NPK', 'Prix du cacao aujourd\'hui', 'Acheter des semences']
  },
  create_product: {
    name: 'Vendre un produit',
    description: 'Mettre un produit en vente',
    params: ['nom', 'prix', 'quantite'],
    examples: ['Je veux vendre 50kg de cacao', 'Mettre en vente des tomates']
  },
  
  // Alertes & Capteurs
  get_alerts: {
    name: 'Voir les alertes',
    description: 'Consulter les alertes actives',
    params: [],
    examples: ['Y a-t-il des alertes?', 'Quelles sont mes notifications?']
  },
  get_sensors: {
    name: 'Données des capteurs',
    description: 'Voir les données des capteurs IoT',
    params: ['parcelle_id'],
    examples: ['Température de ma parcelle', 'Humidité du sol', 'État des capteurs']
  },
  
  // Irrigation
  irrigation_control: {
    name: 'Contrôler l\'irrigation',
    description: 'Activer/désactiver l\'irrigation',
    params: ['parcelle_id', 'action'],
    examples: ['Active l\'arrosage', 'Arrête l\'irrigation', 'Arrose ma parcelle']
  },
  irrigation_schedule: {
    name: 'Programmer l\'irrigation',
    description: 'Planifier l\'arrosage automatique',
    params: ['parcelle_id', 'heure', 'duree'],
    examples: ['Programme l\'arrosage à 6h', 'Arrose pendant 30 minutes chaque matin']
  },
  
  // Conseils
  get_advice: {
    name: 'Obtenir des conseils',
    description: 'Recevoir des conseils agricoles',
    params: ['topic', 'culture'],
    examples: ['Comment cultiver le cacao?', 'Conseils pour l\'igname', 'Quand planter le maïs?']
  },
  
  // Communication
  send_message: {
    name: 'Envoyer un message',
    description: 'Envoyer un message à un autre utilisateur',
    params: ['destinataire', 'message'],
    examples: ['Envoie un message à mon agronome', 'Contacte le fournisseur']
  },
  
  // Formations
  start_training: {
    name: 'Démarrer une formation',
    description: 'Accéder aux formations agricoles',
    params: ['topic'],
    examples: ['Apprends-moi la culture du cacao', 'Formation sur les maladies']
  }
};

/**
 * Réponses prédéfinies en langues locales
 */
const LOCAL_RESPONSES = {
  bci: {
    greeting: 'Aló! N ti AgroSmart uka. Ɔ sɛ man a?',
    weather_good: 'Andɛ wia su nglo kpa. I fie su duman.',
    weather_rain: 'Nzue su ba. Man fa i ninnge mun sie kpa.',
    alert_critical: 'Sa tɛ kpa! Fa i wun nian i fie.',
    irrigation_on: 'Nzue yilɛ su kɔ i fie su.',
    irrigation_off: 'Nzue yilɛ su jrɛn.',
    parcelle_healthy: 'I fie ti kpa! Ɔ su kɔ kpa.',
    parcelle_warning: 'Sa kun o i fie su. Nian i su.',
    thank_you: 'Ɔ ti kpa! N klo wɔ uka.',
    not_understood: 'N ti wun sa wie man srɛ wɔ. Man kle sa i bo?',
    goodbye: 'Kloman! Ka nglɛmun!'
  },
  dyu: {
    greeting: 'I ni sogoma! N ye AgroSmart dɛmɛbaga ye. N bɛ se ka i dɛmɛ cogo di?',
    weather_good: 'Bi tile bɛ ɲi. Waati ka ɲi sɛnɛ ye.',
    weather_rain: 'Sanjii bɛna na. I ka i fɛnw mara.',
    alert_critical: 'Kibaro gɛlɛn! Taa i sɛnɛ lajɛ joona.',
    irrigation_on: 'Ji bɔli daminɛna i sɛnɛ na.',
    irrigation_off: 'Ji bɔli labilara.',
    parcelle_healthy: 'I sɛnɛ ka ɲi! A bɛ taa ɲɛ.',
    parcelle_warning: 'Koo dɔ bɛ i sɛnɛ na. A lajɛ.',
    thank_you: 'A ni ce! N bɛ yen i ka dɛmɛ la.',
    not_understood: 'N ma o faamu. I bɛ se ka o lakana n ye?',
    goodbye: 'K\'an bɛn! Ka tile ɲi!'
  },
  sev: {
    greeting: 'Wali! N ye AgroSmart demebaga ye. N kɔ ye i deme?',
    weather_good: 'Bi yiri ye. Sangari ka di fankan ye.',
    weather_rain: 'Fyɛ bɛna na. I ka i fɛnw mara.',
    alert_critical: 'Tifaari gbɔgɔ! Kàn i fankan lɛɛri joona.',
    irrigation_on: 'Ji feli daminɛna i fankan na.',
    irrigation_off: 'Ji feli labilara.',
    parcelle_healthy: 'I fankan naa nuŋu! A baa taa yee.',
    parcelle_warning: 'Koloo dɔ baa i fankan na. A lɛɛri.',
    thank_you: 'Barikan! N ye yen i deme ye.',
    not_understood: 'N te o faamu. I bɛ se ka o fɔ tugun?',
    goodbye: 'Seyɔ! Ka bi ɲi!'
  }
};

/**
 * Traiter un message utilisateur
 */
exports.processMessage = async (req, res) => {
  try {
    const userId = req.user.id;
    const { message, langue = 'fr', historique = [], contexte } = req.body;

    if (!message || message.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Message requis'
      });
    }

    logger.info('[Chatbot] Message received', { userId, langue, message: message.substring(0, 100) });

    // Détecter l'intention et les entités
    const intent = detectIntent(message, langue);
    const entities = extractEntities(message, langue);

    // Obtenir le contexte utilisateur si nécessaire
    let userContext = null;
    if (intent.needsContext) {
      userContext = await getUserContextData(userId);
    }

    // Générer la réponse
    const response = await generateResponse(intent, entities, userContext, langue, historique);

    // Logger pour analytics
    logger.audit('[Chatbot] Response generated', {
      userId,
      intent: intent.name,
      langue,
      hasAction: !!response.action
    });

    res.json({
      success: true,
      data: {
        reponse: response.text,
        audioUrl: response.audioUrl || null,
        action: response.action || null,
        suggestions: response.suggestions || [],
        langue: langue,
        intent: intent.name,
        confidence: intent.confidence
      }
    });

  } catch (error) {
    logger.error('[Chatbot] Error processing message', { error: error.message });
    res.status(500).json({
      success: false,
      error: 'Erreur lors du traitement du message'
    });
  }
};

/**
 * Traiter une commande vocale
 */
exports.processVoiceCommand = async (req, res) => {
  try {
    const userId = req.user.id;
    const { transcription, langue = 'fr' } = req.body;

    if (!transcription) {
      return res.status(400).json({
        success: false,
        error: 'Transcription requise'
      });
    }

    // Utiliser le même traitement que pour les messages texte
    const intent = detectIntent(transcription, langue);
    const entities = extractEntities(transcription, langue);

    // Pour les commandes vocales, on privilégie les actions directes
    let action = null;
    if (intent.confidence > 0.7 && intent.action) {
      action = {
        type: intent.action,
        params: entities,
        autoExecute: intent.confidence > 0.85
      };
    }

    const response = await generateResponse(intent, entities, null, langue, []);

    res.json({
      success: true,
      data: {
        reponse: response.text,
        action: action,
        spokenResponse: response.spokenText || response.text,
        langue: langue
      }
    });

  } catch (error) {
    logger.error('[Chatbot] Error processing voice command', { error: error.message });
    res.status(500).json({
      success: false,
      error: 'Erreur lors du traitement de la commande vocale'
    });
  }
};

/**
 * Exécuter une action
 */
exports.executeAction = async (req, res) => {
  try {
    const userId = req.user.id;
    const { action, params = {} } = req.body;

    if (!action || !AVAILABLE_ACTIONS[action]) {
      return res.status(400).json({
        success: false,
        error: 'Action non reconnue',
        availableActions: Object.keys(AVAILABLE_ACTIONS)
      });
    }

    logger.info('[Chatbot] Executing action', { userId, action, params });

    let result;

    switch (action) {
      case 'navigate':
        result = { route: params.destination, type: 'navigation' };
        break;

      case 'list_parcelles': {
        const parcelles = await prisma.parcelle.findMany({
          where: { userId, isActive: true },
          select: { id: true, nom: true, superficie: true, cultureActuelle: true, sante: true }
        });
        result = { parcelles, type: 'data' };
        break;
      }

      case 'check_weather': {
        // Récupérer depuis le cache ou l'API météo
        const weatherData = await cache.getOrSetWeather(
          params.location || 'abidjan',
          async () => {
            // Appel API météo ici
            return { temperature: 28, humidity: 75, description: 'Ensoleillé' };
          }
        );
        result = { weather: weatherData, type: 'data' };
        break;
      }

      case 'get_alerts': {
        const alertes = await prisma.alerte.findMany({
          where: { userId, statut: 'NOUVELLE' },
          orderBy: { createdAt: 'desc' },
          take: 10
        });
        result = { alertes, type: 'data' };
        break;
      }

      case 'get_sensors': {
        if (params.parcelle_id) {
          const capteurs = await prisma.capteur.findMany({
            where: { parcelleId: params.parcelle_id },
            include: {
              mesures: {
                orderBy: { timestamp: 'desc' },
                take: 1
              }
            }
          });
          result = { capteurs, type: 'data' };
        } else {
          result = { error: 'Parcelle non spécifiée', type: 'error' };
        }
        break;
      }

      case 'marketplace_search': {
        const produits = await prisma.marketplaceProduit.findMany({
          where: {
            actif: true,
            isActive: true,
            OR: [
              { nom: { contains: params.query || '' } },
              { categorie: { contains: params.categorie || '' } }
            ]
          },
          take: 20
        });
        result = { produits, type: 'data' };
        break;
      }

      case 'get_advice':
        result = await generateAdvice(params.topic, params.culture);
        break;

      default:
        result = { message: 'Action en cours de développement', type: 'pending' };
    }

    res.json({
      success: true,
      data: {
        action,
        result
      }
    });

  } catch (error) {
    logger.error('[Chatbot] Error executing action', { error: error.message });
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'exécution de l\'action'
    });
  }
};

/**
 * Obtenir les actions disponibles
 */
exports.getAvailableActions = async (req, res) => {
  res.json({
    success: true,
    data: {
      actions: AVAILABLE_ACTIONS
    }
  });
};

/**
 * Obtenir les langues supportées
 */
exports.getSupportedLanguages = async (req, res) => {
  res.json({
    success: true,
    data: {
      languages: SUPPORTED_LANGUAGES
    }
  });
};

/**
 * Obtenir le contexte utilisateur
 */
exports.getUserContext = async (req, res) => {
  try {
    const userId = req.user.id;
    const context = await getUserContextData(userId);

    res.json({
      success: true,
      data: context
    });

  } catch (error) {
    logger.error('[Chatbot] Error getting user context', { error: error.message });
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération du contexte'
    });
  }
};

// ============================================
// FONCTIONS UTILITAIRES
// ============================================

/**
 * Détecter l'intention du message
 */
function detectIntent(message, langue) {
  const msgLower = message.toLowerCase();

  // Patterns d'intention avec leurs mots-clés et actions
  const intentPatterns = [
    {
      name: 'greeting',
      keywords: ['bonjour', 'salut', 'allo', 'bonsoir', 'hello', 'hi', 'aló', 'i ni sogoma', 'wali'],
      action: null,
      needsContext: false
    },
    {
      name: 'weather',
      keywords: ['météo', 'temps', 'pluie', 'soleil', 'climat', 'température', 'humidité', 'prévision'],
      action: 'check_weather',
      needsContext: true
    },
    {
      name: 'parcelles_list',
      keywords: ['mes parcelles', 'mes champs', 'liste parcelle', 'voir parcelle', 'montre parcelle'],
      action: 'list_parcelles',
      needsContext: true
    },
    {
      name: 'parcelle_status',
      keywords: ['état parcelle', 'santé parcelle', 'comment va', 'état champ', 'santé culture'],
      action: 'parcelle_status',
      needsContext: true
    },
    {
      name: 'alerts',
      keywords: ['alerte', 'notification', 'problème', 'urgence', 'danger', 'avertissement'],
      action: 'get_alerts',
      needsContext: true
    },
    {
      name: 'irrigation',
      keywords: ['arroser', 'irrigation', 'eau', 'pompe', 'arrosage'],
      action: 'irrigation_control',
      needsContext: true
    },
    {
      name: 'diagnostic',
      keywords: ['maladie', 'diagnostic', 'malade', 'feuille', 'parasite', 'champignon', 'insecte', 'analyser'],
      action: 'diagnose',
      needsContext: true
    },
    {
      name: 'marketplace',
      keywords: ['acheter', 'vendre', 'prix', 'marché', 'produit', 'marketplace', 'boutique'],
      action: 'marketplace_search',
      needsContext: false
    },
    {
      name: 'sensors',
      keywords: ['capteur', 'température', 'humidité', 'sol', 'mesure', 'données', 'iot'],
      action: 'get_sensors',
      needsContext: true
    },
    {
      name: 'advice',
      keywords: ['conseil', 'aide', 'comment', 'pourquoi', 'quand', 'astuce', 'recommandation'],
      action: 'get_advice',
      needsContext: false
    },
    {
      name: 'training',
      keywords: ['formation', 'apprendre', 'cours', 'tutoriel', 'leçon'],
      action: 'start_training',
      needsContext: false
    },
    {
      name: 'navigate',
      keywords: ['va à', 'ouvre', 'montre', 'affiche', 'aller à', 'amène'],
      action: 'navigate',
      needsContext: false
    },
    {
      name: 'goodbye',
      keywords: ['au revoir', 'bye', 'merci', 'à bientôt', 'kloman', 'seyɔ'],
      action: null,
      needsContext: false
    }
  ];

  // Calculer les scores de correspondance
  let bestMatch = { name: 'general', action: null, confidence: 0.3, needsContext: false };

  for (const pattern of intentPatterns) {
    let matchCount = 0;
    for (const keyword of pattern.keywords) {
      if (msgLower.includes(keyword)) {
        matchCount++;
      }
    }

    if (matchCount > 0) {
      const confidence = Math.min(0.95, 0.5 + (matchCount * 0.15));
      if (confidence > bestMatch.confidence) {
        bestMatch = {
          name: pattern.name,
          action: pattern.action,
          confidence,
          needsContext: pattern.needsContext
        };
      }
    }
  }

  return bestMatch;
}

/**
 * Extraire les entités du message
 */
function extractEntities(message, langue) {
  const entities = {};
  const msgLower = message.toLowerCase();

  // Extraire les cultures mentionnées
  const cultures = ['cacao', 'café', 'igname', 'manioc', 'maïs', 'riz', 'palmier', 'hévéa', 'banane', 'tomate', 'aubergine'];
  for (const culture of cultures) {
    if (msgLower.includes(culture)) {
      entities.culture = culture;
      break;
    }
  }

  // Extraire les nombres (superficie, prix, quantité)
  const numberMatch = message.match(/(\d+(?:[.,]\d+)?)\s*(hectare|ha|kg|fcfa|franc|cfa|litre|l)/i);
  if (numberMatch) {
    entities.quantity = parseFloat(numberMatch[1].replace(',', '.'));
    entities.unit = numberMatch[2].toLowerCase();
  }

  // Extraire les destinations de navigation
  const destinations = {
    'parcelle': '/parcelles',
    'champ': '/parcelles',
    'météo': '/weather',
    'temps': '/weather',
    'marché': '/marketplace',
    'boutique': '/marketplace',
    'alerte': '/notifications',
    'notification': '/notifications',
    'profil': '/profile',
    'accueil': '/dashboard',
    'diagnostic': '/diagnostic',
    'formation': '/formations',
    'forum': '/forum',
    'capteur': '/capteurs',
    'message': '/messages'
  };

  for (const [keyword, route] of Object.entries(destinations)) {
    if (msgLower.includes(keyword)) {
      entities.destination = route;
      break;
    }
  }

  return entities;
}

/**
 * Obtenir les données de contexte utilisateur
 */
async function getUserContextData(userId) {
  const [user, parcelles, alertes] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId },
      select: { nom: true, prenoms: true, regionId: true, langue_preferee: true }
    }),
    prisma.parcelle.findMany({
      where: { userId, isActive: true },
      select: { id: true, nom: true, cultureActuelle: true, sante: true }
    }),
    prisma.alerte.count({
      where: { userId, statut: 'NOUVELLE' }
    })
  ]);

  return {
    user: {
      nom: `${user?.prenoms || ''} ${user?.nom || ''}`.trim(),
      langue: user?.langue_preferee || 'fr'
    },
    parcelles: parcelles.map(p => ({
      id: p.id,
      nom: p.nom,
      culture: p.cultureActuelle,
      sante: p.sante
    })),
    alertesCount: alertes
  };
}

/**
 * Générer une réponse
 */
async function generateResponse(intent, entities, context, langue, historique) {
  let text = '';
  let suggestions = [];
  let action = null;

  // Réponses en langue locale si disponible
  const localResponses = LOCAL_RESPONSES[langue] || {};

  switch (intent.name) {
    case 'greeting':
      if (localResponses.greeting) {
        text = localResponses.greeting;
      } else {
        text = `Bonjour! Je suis votre assistant AgroSmart. Comment puis-je vous aider aujourd'hui?`;
      }
      suggestions = ['Voir mes parcelles', 'Météo', 'Alertes', 'Marketplace'];
      break;

    case 'weather':
      if (localResponses.weather_good) {
        text = localResponses.weather_good;
      } else {
        text = `Les conditions météo sont favorables pour vos cultures. Température moyenne de 28°C avec faible probabilité de pluie.`;
      }
      action = { type: 'check_weather', params: entities };
      suggestions = ['Prévisions 7 jours', 'Alertes météo', 'Conseils irrigation'];
      break;

    case 'parcelles_list':
      if (context && context.parcelles.length > 0) {
        const parcellesList = context.parcelles.map(p => `• ${p.nom} (${p.culture || 'sans culture'})`).join('\n');
        text = `Voici vos ${context.parcelles.length} parcelles:\n${parcellesList}`;
      } else {
        text = `Vous n'avez pas encore de parcelles. Voulez-vous en créer une?`;
      }
      action = { type: 'list_parcelles' };
      suggestions = ['Ajouter une parcelle', 'Détails parcelle', 'État des cultures'];
      break;

    case 'alerts':
      if (context && context.alertesCount > 0) {
        if (localResponses.alert_critical) {
          text = `${localResponses.alert_critical} ${context.alertesCount} alertes.`;
        } else {
          text = `Vous avez ${context.alertesCount} alerte(s) active(s). Consultez-les pour protéger vos cultures.`;
        }
      } else {
        text = `Aucune alerte active. Vos parcelles sont en bon état!`;
      }
      action = { type: 'get_alerts' };
      suggestions = ['Voir les alertes', 'Historique alertes', 'Paramètres notifications'];
      break;

    case 'irrigation':
      text = `Je peux contrôler votre système d'irrigation. Voulez-vous activer ou désactiver l'arrosage?`;
      action = { type: 'irrigation_control', params: entities };
      suggestions = ['Activer arrosage', 'Arrêter arrosage', 'Programmer'];
      break;

    case 'diagnostic':
      text = `Pour diagnostiquer vos plantes, prenez une photo claire des symptômes. Je l'analyserai avec notre IA.`;
      action = { type: 'diagnose' };
      suggestions = ['Prendre une photo', 'Historique diagnostics', 'Maladies courantes'];
      break;

    case 'marketplace':
      text = `Que recherchez-vous sur le marketplace? Produits agricoles, semences, engrais, ou matériel?`;
      action = { type: 'marketplace_search', params: entities };
      suggestions = ['Engrais', 'Semences', 'Matériel', 'Mes produits'];
      break;

    case 'advice': {
      const adviceText = await generateAdvice(entities.topic, entities.culture);
      text = adviceText.text || `Je suis là pour vous conseiller sur vos cultures. Quel sujet vous intéresse?`;
      suggestions = ['Calendrier agricole', 'Traitements', 'Bonnes pratiques'];
      break;
    }

    case 'navigate':
      if (entities.destination) {
        text = `Je vous dirige vers cette section.`;
        action = { type: 'navigate', params: { destination: entities.destination } };
      } else {
        text = `Où souhaitez-vous aller?`;
        suggestions = ['Accueil', 'Parcelles', 'Marketplace', 'Météo'];
      }
      break;

    case 'goodbye':
      if (localResponses.goodbye) {
        text = localResponses.goodbye;
      } else {
        text = `Au revoir! N'hésitez pas à revenir si vous avez des questions. Bonne journée!`;
      }
      break;

    default:
      if (localResponses.not_understood) {
        text = localResponses.not_understood;
      } else {
        text = `Je suis votre assistant agricole. Je peux vous aider avec:\n• La météo\n• Vos parcelles\n• Les diagnostics\n• Le marketplace\n• L'irrigation\n\nQue souhaitez-vous faire?`;
      }
      suggestions = ['Météo', 'Parcelles', 'Diagnostic', 'Marketplace'];
  }

  return {
    text,
    spokenText: text, // Peut être différent pour TTS
    suggestions,
    action
  };
}

/**
 * Générer des conseils agricoles
 */
async function generateAdvice(topic, culture) {
  const adviceDatabase = {
    irrigation: {
      general: 'L\'irrigation doit être adaptée à votre type de sol et à la saison. Arrosez tôt le matin pour limiter l\'évaporation.',
      cacao: 'Le cacaoyer nécessite un sol humide mais pas détrempé. Arrosez 2 à 3 fois par semaine en saison sèche.',
      igname: 'L\'igname préfère un sol bien drainé. Évitez l\'excès d\'eau qui favorise le pourrissement.'
    },
    engrais: {
      general: 'Utilisez un engrais NPK équilibré. Le compost et le fumier enrichissent naturellement le sol.',
      cacao: 'Appliquez de l\'engrais au début de la saison des pluies. NPK 20-10-10 recommandé.',
      maïs: 'Le maïs est gourmand en azote. Appliquez de l\'urée en deux fois: au semis et à la montaison.'
    },
    maladie: {
      general: 'Inspectez régulièrement vos plants. Retirez les parties malades et utilisez notre diagnostic IA.',
      cacao: 'Surveillez la pourriture brune et le swollen shoot. Élaguez pour aérer les arbres.',
      tomate: 'Le mildiou et l\'alternariose sont fréquents. Traitez préventivement avec du cuivre.'
    }
  };

  const topicAdvice = adviceDatabase[topic] || adviceDatabase.general;
  const specificAdvice = culture && topicAdvice[culture] 
    ? topicAdvice[culture] 
    : topicAdvice.general || 'Consultez nos formations pour plus de conseils personnalisés.';

  return {
    text: specificAdvice,
    type: 'advice',
    topic,
    culture
  };
}
