/**
 * Routes publiques de démonstration — Mode Visiteur
 * AgroSmart - Système Agricole Intelligent
 *
 * Toutes ces routes sont accessibles SANS authentification.
 * Elles fournissent des données simulées réalistes pour chaque
 * fonctionnalité de la plateforme.
 */

const express = require('express');
const router = express.Router();

// ─────────────────────────────────────────────────────────
// DATA MOCKS — Données centralisées réutilisées par route
// ─────────────────────────────────────────────────────────

const DEMO_PARCELLES = [
  {
    id: 'p1',
    nom: 'Parcelle Cacao Nord',
    superficie: 3.5,
    latitude: 5.3599,
    longitude: -4.0083,
    cultureActuelle: 'Cacao',
    typeSol: 'Argileux',
    statut: 'EN_CROISSANCE',
    sante: 'OPTIMAL',
    sante_globale: 92,
    humidite: 65,
    temperature: 28,
    ph: 6.5,
    npk: { n: 42, p: 18, k: 35 },
    regionId: 'r1',
    region: 'Abidjan',
    datePlantation: '2025-09-15',
    nb_stations: 2,
    nb_capteurs: 6,
    rendement_estime: '1.8 t/ha',
  },
  {
    id: 'p2',
    nom: 'Parcelle Café Centre',
    superficie: 2.1,
    latitude: 5.3600,
    longitude: -4.0081,
    cultureActuelle: 'Café',
    typeSol: 'Limoneux',
    statut: 'EN_CROISSANCE',
    sante: 'SURVEILLANCE',
    sante_globale: 68,
    humidite: 42,
    temperature: 31,
    ph: 6.0,
    npk: { n: 28, p: 12, k: 22 },
    regionId: 'r1',
    region: 'Abidjan',
    datePlantation: '2025-10-01',
    nb_stations: 1,
    nb_capteurs: 4,
    rendement_estime: '0.9 t/ha',
  },
  {
    id: 'p3',
    nom: 'Parcelle Plantain Est',
    superficie: 1.8,
    latitude: 5.3598,
    longitude: -4.0085,
    cultureActuelle: 'Plantain',
    typeSol: 'Sableux',
    statut: 'RECOLTE',
    sante: 'OPTIMAL',
    sante_globale: 88,
    humidite: 78,
    temperature: 26,
    ph: 7.2,
    npk: { n: 55, p: 24, k: 48 },
    regionId: 'r2',
    region: 'Yamoussoukro',
    datePlantation: '2025-07-10',
    nb_stations: 1,
    nb_capteurs: 3,
    rendement_estime: '12 t/ha',
  },
];

const DEMO_CAPTEURS = [
  { id: 'c1', parcelleId: 'p1', nom: 'Capteur Sol Nord-A', type: 'HUMIDITE_SOL', statut: 'ACTIF', batterie: 87, signal: 95, valeur: 65, unite: '%' },
  { id: 'c2', parcelleId: 'p1', nom: 'Capteur Ambiant Nord-B', type: 'HUMIDITE_TEMPERATURE_AMBIANTE', statut: 'ACTIF', batterie: 92, signal: 88, valeur: 28.4, unite: '°C' },
  { id: 'c3', parcelleId: 'p1', nom: 'Capteur NPK Nord-C', type: 'NPK', statut: 'ACTIF', batterie: 74, signal: 82, valeur: null, unite: 'mg/kg' },
  { id: 'c4', parcelleId: 'p2', nom: 'Capteur Sol Centre-A', type: 'HUMIDITE_SOL', statut: 'ACTIF', batterie: 61, signal: 79, valeur: 42, unite: '%' },
  { id: 'c5', parcelleId: 'p2', nom: 'Capteur Ambiant Centre-B', type: 'HUMIDITE_TEMPERATURE_AMBIANTE', statut: 'MAINTENANCE', batterie: 38, signal: 55, valeur: 31.2, unite: '°C' },
  { id: 'c6', parcelleId: 'p3', nom: 'Capteur Sol Est-A', type: 'HUMIDITE_SOL', statut: 'ACTIF', batterie: 95, signal: 98, valeur: 78, unite: '%' },
];

const DEMO_MESURES = Array.from({ length: 24 }, (_, i) => ({
  id: `m${i}`,
  capteurId: 'c1',
  valeur: 60 + Math.round(Math.random() * 20),
  unite: '%',
  timestamp: new Date(Date.now() - i * 3600000).toISOString(),
  type: 'HUMIDITE_SOL',
}));

const DEMO_ALERTES = [
  {
    id: 'a1',
    type: 'irrigation',
    niveau: 'IMPORTANT',
    titre: 'Stress hydrique détecté',
    message: 'Humidité du sol en dessous de 45% sur Parcelle Café Centre. Irrigation recommandée dans les 6h.',
    statut: 'NOUVELLE',
    parcelleId: 'p2',
    parcelle_nom: 'Parcelle Café Centre',
    createdAt: new Date(Date.now() - 2 * 3600000).toISOString(),
  },
  {
    id: 'a2',
    type: 'maladie',
    niveau: 'IMPORTANT',
    titre: 'Risque feuille noire cacao',
    message: 'Conditions météo (humidité > 80%, T° > 27°C) favorables à Phytophthora. Inspection recommandée.',
    statut: 'NOUVELLE',
    parcelleId: 'p1',
    parcelle_nom: 'Parcelle Cacao Nord',
    createdAt: new Date(Date.now() - 4 * 3600000).toISOString(),
  },
  {
    id: 'a3',
    type: 'temperature',
    niveau: 'INFO',
    titre: 'Température élevée',
    message: 'Température > 30°C sur Parcelle Café. Stress thermique possible pour le café arabica.',
    statut: 'LUE',
    parcelleId: 'p2',
    parcelle_nom: 'Parcelle Café Centre',
    createdAt: new Date(Date.now() - 1 * 3600000).toISOString(),
  },
  {
    id: 'a4',
    type: 'npk',
    niveau: 'INFO',
    titre: 'Carence en azote détectée',
    message: 'Taux d\'azote (N=28 mg/kg) en dessous de la norme recommandée. Fertilisation conseillée.',
    statut: 'NOUVELLE',
    parcelleId: 'p2',
    parcelle_nom: 'Parcelle Café Centre',
    createdAt: new Date(Date.now() - 8 * 3600000).toISOString(),
  },
];

const DEMO_METEO = {
  actuelle: {
    temperature: 28.5,
    humidite: 72,
    pression: 1013,
    vitesse_vent: 12,
    direction_vent: 'SW',
    description: 'Partiellement nuageux',
    icon: '⛅',
    precipitation_mm: 0,
  },
  previsions: [
    { jour: 'Aujourd\'hui', temperature_max: 31, temperature_min: 23, icon: '⛅', precipitation: 10, description: 'Partiellement nuageux' },
    { jour: 'Demain', temperature_max: 29, temperature_min: 22, icon: '🌧', precipitation: 65, description: 'Averses' },
    { jour: 'Mer', temperature_max: 27, temperature_min: 21, icon: '🌦', precipitation: 40, description: 'Pluies légères' },
    { jour: 'Jeu', temperature_max: 30, temperature_min: 23, icon: '☀', precipitation: 5, description: 'Ensoleillé' },
    { jour: 'Ven', temperature_max: 32, temperature_min: 24, icon: '☀', precipitation: 0, description: 'Ensoleillé' },
    { jour: 'Sam', temperature_max: 31, temperature_min: 23, icon: '⛅', precipitation: 15, description: 'Quelques nuages' },
    { jour: 'Dim', temperature_max: 28, temperature_min: 22, icon: '🌧', precipitation: 70, description: 'Orages possibles' },
    { jour: 'Lun', temperature_max: 26, temperature_min: 21, icon: '🌦', precipitation: 45, description: 'Pluies' },
    { jour: 'Mar', temperature_max: 29, temperature_min: 22, icon: '⛅', precipitation: 20, description: 'Nuages épars' },
    { jour: 'Mer+1', temperature_max: 30, temperature_min: 23, icon: '☀', precipitation: 5, description: 'Ensoleillé' },
  ],
  alertes_meteo: [
    { type: 'pluie', titre: 'Averses demain', description: 'Risque de pluies intenses (>20mm). Reportez les traitements phytosanitaires.' },
  ],
};

const DEMO_RECOMMANDATIONS = [
  {
    id: 'rec1',
    titre: 'Irrigation urgente — Parcelle Café',
    description: 'L\'humidité sol est à 42%, en dessous du seuil critique de 50% pour le café. Arrosez 25-30L/m² dans les prochaines heures.',
    type: 'irrigation',
    priorite: 1,
    parcelleId: 'p2',
    parcelle_nom: 'Parcelle Café Centre',
    culture: 'Café',
    action: 'Arroser',
    delai_heures: 6,
    economie_potentielle_fcfa: 45000,
    appliquee: false,
    generePar: 'IA',
  },
  {
    id: 'rec2',
    titre: 'Application NPK — Parcelle Café',
    description: 'Taux d\'azote insuffisant. Appliquer 150 kg/ha d\'engrais NPK 20-10-10 avant la prochaine pluie prévue demain.',
    type: 'fertilisation',
    priorite: 2,
    parcelleId: 'p2',
    parcelle_nom: 'Parcelle Café Centre',
    culture: 'Café',
    action: 'Fertiliser',
    delai_heures: 24,
    economie_potentielle_fcfa: 120000,
    appliquee: false,
    generePar: 'IA',
  },
  {
    id: 'rec3',
    titre: 'Inspection phytosanitaire — Cacao',
    description: 'Conditions propices à la feuille noire (Phytophthora). Inspectez quotidiennement les cabosses et feuilles. Appliquez bouillie bordelaise si symptômes.',
    type: 'prevention',
    priorite: 2,
    parcelleId: 'p1',
    parcelle_nom: 'Parcelle Cacao Nord',
    culture: 'Cacao',
    action: 'Inspecter',
    delai_heures: 48,
    economie_potentielle_fcfa: 200000,
    appliquee: false,
    generePar: 'IA',
  },
  {
    id: 'rec4',
    titre: 'Récolte plantain — Optimal',
    description: 'La parcelle plantain atteint maturité optimale. Programmez la récolte cette semaine pour maximiser la qualité.',
    type: 'recolte',
    priorite: 3,
    parcelleId: 'p3',
    parcelle_nom: 'Parcelle Plantain Est',
    culture: 'Plantain',
    action: 'Récolter',
    delai_heures: 72,
    economie_potentielle_fcfa: 80000,
    appliquee: false,
    generePar: 'IA',
  },
];

const DEMO_DIAGNOSTICS = [
  {
    id: 'd1',
    culture: 'Cacao',
    maladie: 'Pourriture brune (Phytophthora palmivora)',
    confiance: 87.3,
    gravite: 'Modérée',
    symptomes: ['Taches brunes sur cabosses', 'Pourriture des racines', 'Flétrissement feuilles'],
    traitements: [
      'Application de bouillie bordelaise (10g/L)',
      'Enlever et brûler les parties infectées',
      'Améliorer le drainage',
    ],
    prevention: ['Espacement entre plants de 3m min', 'Taille régulière pour aération'],
    image_url: null,
    date: new Date(Date.now() - 86400000).toISOString(),
  },
  {
    id: 'd2',
    culture: 'Café',
    maladie: 'Rouille orangée (Hemileia vastatrix)',
    confiance: 93.1,
    gravite: 'Élevée',
    symptomes: ['Poudre orangée sous les feuilles', 'Jaunissement feuilles', 'Défoliation précoce'],
    traitements: [
      'Fongicide à base de cuivre (3kg/ha)',
      'Retirer les feuilles atteintes',
      'Améliorer la ventilation',
    ],
    prevention: ['Variétés résistantes', 'Surveillance hebdomadaire'],
    image_url: null,
    date: new Date(Date.now() - 3 * 86400000).toISOString(),
  },
];

const DEMO_FORMATIONS = [
  {
    id: 'f1',
    titre: 'Gestion de l\'irrigation au goutte-à-goutte',
    description: 'Apprenez à économiser 40% d\'eau avec les techniques d\'irrigation de précision adaptées aux cultures ivoiriennes.',
    categorie: 'Irrigation',
    niveau: 'Débutant',
    dureeMinutes: 45,
    vues: 1247,
    progression: 0,
    modules: 6,
    imageUrl: null,
  },
  {
    id: 'f2',
    titre: 'Détection précoce des maladies du cacao',
    description: 'Identifiez les 10 principales maladies du cacao ivoirien avant qu\'elles impactent vos rendements.',
    categorie: 'Phytosanitaire',
    niveau: 'Intermédiaire',
    dureeMinutes: 60,
    vues: 892,
    progression: 30,
    modules: 8,
    imageUrl: null,
  },
  {
    id: 'f3',
    titre: 'Fertilisation raisonnée avec le NPK',
    description: 'Optimisez vos apports en engrais grâce aux données IoT et réduisez vos coûts de 25%.',
    categorie: 'Fertilisation',
    niveau: 'Intermédiaire',
    dureeMinutes: 35,
    vues: 534,
    progression: 0,
    modules: 5,
    imageUrl: null,
  },
  {
    id: 'f4',
    titre: 'Utilisation de l\'application AgroSmart',
    description: 'Maîtrisez toutes les fonctionnalités de l\'application pour maximiser votre productivité.',
    categorie: 'Numérique',
    niveau: 'Débutant',
    dureeMinutes: 20,
    vues: 2108,
    progression: 100,
    modules: 4,
    imageUrl: null,
  },
];

const DEMO_FICHES_PRATIQUES = [
  { id: 'fp1', titre: 'Guide du cacao — Plantation et entretien', categorie: 'Cacao', langue: 'fr', pages: 12 },
  { id: 'fp2', titre: 'Calendrier cultural maïs — Côte d\'Ivoire', categorie: 'Céréales', langue: 'fr', pages: 8 },
  { id: 'fp3', titre: 'Gestion intégrée des ravageurs', categorie: 'Phytosanitaire', langue: 'fr', pages: 15 },
  { id: 'fp4', titre: 'Compostage et fertilisation organique', categorie: 'Sol', langue: 'fr', pages: 10 },
  { id: 'fp5', titre: 'Fiche maladie — Pourriture brune cacao', categorie: 'Maladies', langue: 'fr', pages: 5 },
  { id: 'fp6', titre: 'Irrigation de précision — Pratique terrain', categorie: 'Irrigation', langue: 'fr', pages: 9 },
];

const DEMO_MARKETPLACE = [
  {
    id: 'mp1',
    nom: 'Semences de Maïs Hybride SAMARU 2Y',
    description: 'Variété à haut rendement adaptée aux sols ivoiriens. Rendement moyen 6t/ha. Certifiée CNRA.',
    categorie: 'Semences',
    prix: 12500,
    unite: 'kg',
    stock: 500,
    typeOffre: 'vente',
    vendeur: 'Coopérative COOPAG Bouaké',
    note: 4.7,
    nb_avis: 23,
    images: [],
  },
  {
    id: 'mp2',
    nom: 'Engrais NPK 20-10-10 (50kg)',
    description: 'Engrais complet idéal pour café et cacao en phase de croissance. Homologué.',
    categorie: 'Engrais',
    prix: 18000,
    unite: 'sac',
    stock: 200,
    typeOffre: 'vente',
    vendeur: 'AgriIntrants Abidjan',
    note: 4.5,
    nb_avis: 45,
    images: [],
  },
  {
    id: 'mp3',
    nom: 'Tracteur John Deere 5E — Location',
    description: 'Tracteur 75CV disponible à la location. Opérateur inclus. Zone Abidjan & environs.',
    categorie: 'Équipement',
    prix: 35000,
    unite: 'jour',
    stock: 1,
    typeOffre: 'location',
    prixLocationJour: 35000,
    caution: 150000,
    dureeMinLocation: 1,
    vendeur: 'MecaAgri CI',
    note: 4.9,
    nb_avis: 12,
    images: [],
  },
  {
    id: 'mp4',
    nom: 'Récolte Cacao grade 1 (100kg)',
    description: 'Fèves de cacao séchées grade 1, humidité <7%. Certification UTZ disponible.',
    categorie: 'Récoltes',
    prix: 165000,
    unite: 'sac',
    stock: 50,
    typeOffre: 'vente',
    vendeur: 'Kouassi Jean-Baptiste',
    note: 4.8,
    nb_avis: 8,
    images: [],
  },
  {
    id: 'mp5',
    nom: 'Pulvérisateur dorsal 16L',
    description: 'Pulvérisateur manuel haute performance pour traitement phytosanitaire. Livraison gratuite.',
    categorie: 'Équipement',
    prix: 24500,
    unite: 'pièce',
    stock: 30,
    typeOffre: 'vente',
    vendeur: 'AgriOutillage Yamoussoukro',
    note: 4.2,
    nb_avis: 18,
    images: [],
  },
  {
    id: 'mp6',
    nom: 'Fongicide Ridomil Gold (1kg)',
    description: 'Fongicide systémique contre mildiou et Phytophthora. Efficace sur cacao et tomate.',
    categorie: 'Pesticides',
    prix: 8500,
    unite: 'kg',
    stock: 80,
    typeOffre: 'vente',
    vendeur: 'PhytoSolutions CI',
    note: 4.6,
    nb_avis: 31,
    images: [],
  },
];

const DEMO_ACHATS_GROUPES = [
  {
    id: 'ag1',
    titre: 'Achat groupé engrais NPK — Saison rains 2026',
    description: 'Réunissez-vous pour acheter l\'engrais NPK 20-10-10 à prix réduit. Commande minimum 5 tonnes.',
    categorie: 'Engrais',
    prixUnitaire: 18000,
    prixGroupe: 13500,
    reduction: 25,
    quantiteObjectif: 100,
    quantiteActuelle: 73,
    dateLimite: new Date(Date.now() + 10 * 86400000).toISOString(),
    participants: 18,
    statut: 'en_cours',
  },
  {
    id: 'ag2',
    titre: 'Groupage semences riz IR64',
    description: 'Semences certifiées riz à haut rendement. Commande groupée pour réduction 30%.',
    categorie: 'Semences',
    prixUnitaire: 9000,
    prixGroupe: 6300,
    reduction: 30,
    quantiteObjectif: 50,
    quantiteActuelle: 32,
    dateLimite: new Date(Date.now() + 7 * 86400000).toISOString(),
    participants: 12,
    statut: 'en_cours',
  },
];

const DEMO_FORUM = [
  {
    id: 'fo1',
    titre: 'Comment gérer la feuille noire sur le cacao cette saison ?',
    auteur: 'Kouassi Koffi',
    avatar: null,
    categorie: 'Maladies',
    vues: 156,
    reponses: 8,
    resolu: false,
    createdAt: new Date(Date.now() - 2 * 86400000).toISOString(),
    preview: 'Cette année les pluies ont favorisé le développement de Phytophthora sur mes cacaoyers...',
  },
  {
    id: 'fo2',
    titre: 'Meilleures périodes de plantation maïs en zone forêt',
    auteur: 'Traoré Aminata',
    avatar: null,
    categorie: 'Cultures',
    vues: 234,
    reponses: 15,
    resolu: true,
    createdAt: new Date(Date.now() - 5 * 86400000).toISOString(),
    preview: 'Je voudrais connaître les meilleures dates de semis pour maximiser le rendement...',
  },
  {
    id: 'fo3',
    titre: 'Retour d\'expérience : drip irrigation sur tomate',
    auteur: 'Yao Bernard',
    avatar: null,
    categorie: 'Irrigation',
    vues: 89,
    reponses: 4,
    resolu: false,
    createdAt: new Date(Date.now() - 1 * 86400000).toISOString(),
    preview: 'Après 3 mois d\'utilisation du goutte-à-goutte, j\'ai économisé 40% d\'eau...',
  },
  {
    id: 'fo4',
    titre: 'Capteur NPK : interprétation des valeurs',
    auteur: 'Diallo Ibrahima',
    avatar: null,
    categorie: 'IoT',
    vues: 198,
    reponses: 11,
    resolu: true,
    createdAt: new Date(Date.now() - 3 * 86400000).toISOString(),
    preview: 'Mon capteur NPK affiche N=28, P=12, K=22. Est-ce que c\'est correct pour du café ?',
  },
];

const DEMO_GAMIFICATION = {
  points_total: 1240,
  niveau: 5,
  niveau_nom: 'Agriculteur Confirmé',
  prochain_niveau: 'Expert',
  points_prochain: 1500,
  actions_completees: 34,
  badges: [
    { id: 'b1', nom: 'Premier Pas', description: 'Créer votre première parcelle', icone: '🌱', obtenu: true },
    { id: 'b2', nom: 'Observateur', description: 'Consulter 10 alertes', icone: '👁', obtenu: true },
    { id: 'b3', nom: 'Agronome Digital', description: 'Compléter 3 formations', icone: '🎓', obtenu: true },
    { id: 'b4', nom: 'Commerçant', description: 'Effectuer un achat sur le marketplace', icone: '🛒', obtenu: false },
    { id: 'b5', nom: 'Communautaire', description: 'Répondre à 5 questions du forum', icone: '💬', obtenu: false },
    { id: 'b6', nom: 'Expert IA', description: 'Utiliser le diagnostic IA 10 fois', icone: '🤖', obtenu: false },
  ],
  historique_recent: [
    { action: 'Formation complétée', points: 50, date: new Date(Date.now() - 86400000).toISOString() },
    { action: 'Recommandation appliquée', points: 30, date: new Date(Date.now() - 2 * 86400000).toISOString() },
    { action: 'Discussion forum créée', points: 20, date: new Date(Date.now() - 3 * 86400000).toISOString() },
  ],
};

const DEMO_PERFORMANCE = {
  roi: {
    cout_total_fcfa: 1250000,
    revenu_total_fcfa: 3875000,
    benefice_net_fcfa: 2625000,
    roi_pourcentage: 210,
    trend: 'hausse',
  },
  economies: {
    eau_economisee_pourcentage: 32,
    engrais_economise_pourcentage: 24,
    pertes_evitees_pourcentage: 38,
    valeur_eau_fcfa: 85000,
    valeur_engrais_fcfa: 120000,
    valeur_pertes_fcfa: 340000,
    economies_totales_fcfa: 545000,
  },
  rendements: [
    { culture: 'Cacao', annee: 2024, rendement_kg_ha: 520, rendement_optimal: 800, progression: 65 },
    { culture: 'Café', annee: 2024, rendement_kg_ha: 380, rendement_optimal: 600, progression: 63 },
    { culture: 'Plantain', annee: 2024, rendement_kg_ha: 11500, rendement_optimal: 15000, progression: 77 },
  ],
  comparaison: {
    rendement_moyen_national: 2200,
    rendement_utilisateur: 2850,
    superieur_de: 29.5,
  },
};

const DEMO_CALENDRIER = [
  {
    id: 'cal1',
    titre: 'Arrosage Parcelle Café',
    typeActivite: 'ARROSAGE',
    statut: 'PLANIFIEE',
    priorite: 'URGENTE',
    dateDebut: new Date(Date.now() + 6 * 3600000).toISOString(),
    parcelleId: 'p2',
    parcelle_nom: 'Parcelle Café Centre',
    culture: 'Café',
    coutEstime: 5000,
  },
  {
    id: 'cal2',
    titre: 'Fertilisation NPK — Cacao',
    typeActivite: 'FERTILISATION',
    statut: 'PLANIFIEE',
    priorite: 'HAUTE',
    dateDebut: new Date(Date.now() + 2 * 86400000).toISOString(),
    parcelleId: 'p1',
    parcelle_nom: 'Parcelle Cacao Nord',
    culture: 'Cacao',
    coutEstime: 45000,
  },
  {
    id: 'cal3',
    titre: 'Récolte Plantain',
    typeActivite: 'RECOLTE',
    statut: 'PLANIFIEE',
    priorite: 'HAUTE',
    dateDebut: new Date(Date.now() + 4 * 86400000).toISOString(),
    parcelleId: 'p3',
    parcelle_nom: 'Parcelle Plantain Est',
    culture: 'Plantain',
    coutEstime: 15000,
  },
  {
    id: 'cal4',
    titre: 'Inspection phytosanitaire',
    typeActivite: 'TRAITEMENT',
    statut: 'TERMINEE',
    priorite: 'MOYENNE',
    dateDebut: new Date(Date.now() - 86400000).toISOString(),
    parcelleId: 'p1',
    parcelle_nom: 'Parcelle Cacao Nord',
    culture: 'Cacao',
    coutEstime: 8000,
  },
];

const DEMO_STOCKS = [
  { id: 's1', nom: 'Engrais NPK 20-10-10', categorie: 'ENGRAIS', quantite: 125, unite: 'kg', seuilAlerte: 50, prixUnitaire: 360, dateExpiration: null, statut: 'OK' },
  { id: 's2', nom: 'Semences Maïs Hybride', categorie: 'SEMENCES', quantite: 8, unite: 'kg', seuilAlerte: 10, prixUnitaire: 2500, dateExpiration: '2026-08-01', statut: 'BAS' },
  { id: 's3', nom: 'Bouillie bordelaise', categorie: 'PESTICIDES', quantite: 15, unite: 'kg', seuilAlerte: 5, prixUnitaire: 3200, dateExpiration: '2026-12-31', statut: 'OK' },
  { id: 's4', nom: 'Cacao grade 1 en stock', categorie: 'RECOLTES', quantite: 250, unite: 'kg', seuilAlerte: 100, prixUnitaire: 1650, dateExpiration: null, statut: 'OK' },
  { id: 's5', nom: 'Herbicide glyphosate', categorie: 'HERBICIDES', quantite: 2, unite: 'L', seuilAlerte: 5, prixUnitaire: 4500, dateExpiration: '2026-06-30', statut: 'CRITIQUE' },
];

const DEMO_MALADIES = [
  { id: 'mal1', nom: 'Pourriture brune du cacao', type: 'Fongique', cultures: ['Cacao'], gravite: 'Élevée', pertes_potentielles: '30-70%' },
  { id: 'mal2', nom: 'Rouille orangée du café', type: 'Fongique', cultures: ['Café'], gravite: 'Élevée', pertes_potentielles: '20-50%' },
  { id: 'mal3', nom: 'Cercosporiose du bananier', type: 'Fongique', cultures: ['Plantain', 'Banane'], gravite: 'Modérée', pertes_potentielles: '10-30%' },
  { id: 'mal4', nom: 'Striga (Witch weed)', type: 'Parasite', cultures: ['Maïs', 'Sorgho'], gravite: 'Élevée', pertes_potentielles: '20-80%' },
];

// ─────────────────────────────────────────────────────────
// ROUTES
// ─────────────────────────────────────────────────────────

/** Résumé global pour le dashboard visiteur */
router.get('/dashboard', (req, res) => {
  res.json({
    success: true,
    data: {
      stats_plateforme: {
        total_agriculteurs: 5247,
        total_hectares: 51230,
        capteurs_actifs: 14580,
        alertes_traitees_ce_mois: 892,
        formations_suivies: 3241,
        transactions_marketplace: 1876,
      },
      parcelles: DEMO_PARCELLES,
      alertes_recentes: DEMO_ALERTES.slice(0, 3),
      recommandations_urgentes: DEMO_RECOMMANDATIONS.slice(0, 2),
      meteo_actuelle: DEMO_METEO.actuelle,
      performance_resume: {
        roi_pourcentage: DEMO_PERFORMANCE.roi.roi_pourcentage,
        economies_totales_fcfa: DEMO_PERFORMANCE.economies.economies_totales_fcfa,
        rendement_superieur_national: DEMO_PERFORMANCE.comparaison.superieur_de,
      },
      gamification: {
        points_total: DEMO_GAMIFICATION.points_total,
        niveau_nom: DEMO_GAMIFICATION.niveau_nom,
        badges_obtenus: DEMO_GAMIFICATION.badges.filter(b => b.obtenu).length,
      },
    },
    note: 'Données de démonstration. Créez un compte pour accéder à vos vraies données.',
  });
});

/** Parcelles simulées */
router.get('/parcelles', (req, res) => {
  res.json({
    success: true,
    data: DEMO_PARCELLES,
    count: DEMO_PARCELLES.length,
    note: 'Données simulées. Inscrivez-vous pour gérer vos vraies parcelles.',
  });
});

router.get('/parcelles/:id', (req, res) => {
  const parcelle = DEMO_PARCELLES.find(p => p.id === req.params.id) || DEMO_PARCELLES[0];
  res.json({ success: true, data: parcelle });
});

/** Capteurs IoT */
router.get('/capteurs', (req, res) => {
  const { parcelleId } = req.query;
  const capteurs = parcelleId
    ? DEMO_CAPTEURS.filter(c => c.parcelleId === parcelleId)
    : DEMO_CAPTEURS;
  res.json({ success: true, data: capteurs, count: capteurs.length });
});

/** Mesures temps réel (24h) */
router.get('/mesures', (req, res) => {
  res.json({
    success: true,
    data: DEMO_MESURES,
    count: DEMO_MESURES.length,
    note: 'Historique 24h simulé. Données IoT réelles après connexion.',
  });
});

/** Alertes */
router.get('/alertes', (req, res) => {
  res.json({
    success: true,
    data: DEMO_ALERTES,
    count: DEMO_ALERTES.length,
    non_lues: DEMO_ALERTES.filter(a => a.statut === 'NOUVELLE').length,
    note: 'Alertes simulées. Recevez de vraies alertes SMS/WhatsApp après inscription.',
  });
});

/** Météo 10 jours */
router.get('/meteo', (req, res) => {
  res.json({
    success: true,
    data: DEMO_METEO,
    region: { nom: 'Abidjan, Côte d\'Ivoire', latitude: 5.3599, longitude: -4.0083 },
    note: 'Météo hyperlocale simulée. Données réelles OpenWeather après connexion.',
  });
});

/** Recommandations IA */
router.get('/recommandations', (req, res) => {
  res.json({
    success: true,
    data: DEMO_RECOMMANDATIONS,
    count: DEMO_RECOMMANDATIONS.length,
    note: 'Recommandations IA simulées. Après connexion, elles sont personnalisées à vos parcelles.',
  });
});

/** Diagnostic maladies (IA) */
router.get('/diagnostics', (req, res) => {
  res.json({
    success: true,
    data: DEMO_DIAGNOSTICS,
    count: DEMO_DIAGNOSTICS.length,
    note: 'Diagnostics simulés. Utilisez la caméra de l\'app pour analyser vos plantes en temps réel.',
  });
});

/** Maladies connues */
router.get('/maladies', (req, res) => {
  res.json({
    success: true,
    data: DEMO_MALADIES,
    count: DEMO_MALADIES.length,
  });
});

/** Formations */
router.get('/formations', (req, res) => {
  res.json({
    success: true,
    data: DEMO_FORMATIONS,
    count: DEMO_FORMATIONS.length,
    note: 'Accédez à toutes les formations avec votre compte.',
  });
});

/** Fiches pratiques */
router.get('/fiches-pratiques', (req, res) => {
  res.json({
    success: true,
    data: DEMO_FICHES_PRATIQUES,
    count: DEMO_FICHES_PRATIQUES.length,
  });
});

/** Marketplace produits */
router.get('/marketplace', (req, res) => {
  const { categorie } = req.query;
  const produits = categorie
    ? DEMO_MARKETPLACE.filter(p => p.categorie.toLowerCase() === categorie.toLowerCase())
    : DEMO_MARKETPLACE;
  res.json({
    success: true,
    data: produits,
    count: produits.length,
    categories: ['Semences', 'Engrais', 'Équipement', 'Récoltes', 'Pesticides'],
    note: 'Achetez, vendez et louez après inscription.',
  });
});

router.get('/marketplace/:id', (req, res) => {
  const produit = DEMO_MARKETPLACE.find(p => p.id === req.params.id) || DEMO_MARKETPLACE[0];
  res.json({ success: true, data: produit });
});

/** Achats groupés */
router.get('/group-purchases', (req, res) => {
  res.json({
    success: true,
    data: DEMO_ACHATS_GROUPES,
    count: DEMO_ACHATS_GROUPES.length,
    note: 'Rejoignez des achats groupés pour réduire vos coûts.',
  });
});

/** Forum / Communauté */
router.get('/forum', (req, res) => {
  res.json({
    success: true,
    data: DEMO_FORUM,
    count: DEMO_FORUM.length,
    stats: { membres: 5247, discussions: 1234, reponses: 8976 },
    note: 'Participez à la communauté après inscription.',
  });
});

/** Calendrier agricole */
router.get('/calendrier', (req, res) => {
  res.json({
    success: true,
    data: DEMO_CALENDRIER,
    count: DEMO_CALENDRIER.length,
    note: 'Planifiez toutes vos activités agricoles avec le calendrier intelligent.',
  });
});

/** Stocks */
router.get('/stocks', (req, res) => {
  const alertes = DEMO_STOCKS.filter(s => s.statut !== 'OK');
  res.json({
    success: true,
    data: DEMO_STOCKS,
    count: DEMO_STOCKS.length,
    nb_alertes: alertes.length,
    valeur_totale_fcfa: DEMO_STOCKS.reduce((sum, s) => sum + s.quantite * s.prixUnitaire, 0),
    note: 'Gérez votre inventaire et recevez des alertes de stock bas.',
  });
});

/** Performance & ROI */
router.get('/performance', (req, res) => {
  res.json({
    success: true,
    data: DEMO_PERFORMANCE,
    note: 'Suivez votre ROI et économies en temps réel après connexion.',
  });
});

/** Gamification */
router.get('/gamification', (req, res) => {
  res.json({
    success: true,
    data: DEMO_GAMIFICATION,
    note: 'Gagnez des points et badges en utilisant la plateforme.',
  });
});

/** Statistiques globales plateforme */
router.get('/stats', (req, res) => {
  res.json({
    success: true,
    data: {
      plateforme: {
        total_agriculteurs: 5247,
        total_hectares_connectes: 51230,
        total_capteurs: 14580,
        reduction_pertes_moyenne: '38%',
        augmentation_rendement_moyenne: '25%',
        economies_eau_moyenne: '32%',
      },
      utilisateur_demo: {
        nb_parcelles: 3,
        nb_capteurs_actifs: 5,
        nb_alertes_actives: 3,
        score_sante_moyen: 83,
        roi_pourcentage: 210,
        economies_totales_fcfa: 545000,
      },
      region: {
        nom: 'Abidjan, Côte d\'Ivoire',
        climat: 'Tropical humide',
        cultures_principales: ['Cacao', 'Café', 'Plantain', 'Maïs', 'Manioc'],
        saison_actuelle: 'Grande saison des pluies',
        humidite_moyenne: 72,
        temperature_moyenne: 28,
      },
    },
    note: 'Données simulées pour la démonstration.',
  });
});

/** Liste des fonctionnalités */
router.get('/features', (req, res) => {
  res.json({
    success: true,
    data: [
      { id: 'iot', nom: 'Suivi IoT temps réel', description: 'Humidité sol, température, pH, NPK — toutes les 15 minutes', icon: 'wifi', disponible: true },
      { id: 'meteo', nom: 'Météo hyperlocale 10j', description: 'Prévisions précises avec alertes sécheresse et orages', icon: 'cloud', disponible: true },
      { id: 'alertes', nom: 'Alertes intelligentes', description: 'Notifications SMS/WhatsApp en cas de stress hydrique ou maladies', icon: 'bell', disponible: true },
      { id: 'ia', nom: 'IA Diagnostic', description: 'Détection automatique de 50+ maladies avec 94% de précision par photo', icon: 'camera', disponible: true },
      { id: 'recommandations', nom: 'Recommandations IA', description: 'Conseils personnalisés sur irrigation, fertilisation, phytosanitaire', icon: 'brain', disponible: true },
      { id: 'marketplace', nom: 'Marketplace agricole', description: 'Achat/vente semences, engrais, équipements. Location matériel.', icon: 'shopping-cart', disponible: true },
      { id: 'communaute', nom: 'Communauté', description: 'Forum d\'entraide entre agriculteurs. Partage de bonnes pratiques.', icon: 'users', disponible: true },
      { id: 'formations', nom: 'Formations vidéo', description: 'Tutoriels sur l\'irrigation, maladies, fertilisation, IoT...', icon: 'graduation-cap', disponible: true },
      { id: 'calendrier', nom: 'Calendrier agricole', description: 'Planning intelligent de toutes vos activités avec rappels', icon: 'calendar', disponible: true },
      { id: 'stocks', nom: 'Gestion des stocks', description: 'Suivi inventaire intrants et récoltes. Alertes stock bas.', icon: 'package', disponible: true },
      { id: 'performance', nom: 'Performance & ROI', description: 'Calcul automatique retour sur investissement et économies', icon: 'trending-up', disponible: true },
      { id: 'gamification', nom: 'Gamification', description: 'Points, badges et niveaux pour encourager les bonnes pratiques', icon: 'award', disponible: true },
      { id: 'multiplateforme', nom: 'Android / iOS / Web', description: 'Application disponible partout. Hors-ligne sur mobile.', icon: 'smartphone', disponible: true },
      { id: 'multilangue', nom: 'Multilingue', description: 'Français, baoulé, malinké. Interface vocale pour illettrés.', icon: 'globe', disponible: true },
    ],
    total: 14,
  });
});

module.exports = router;
