/**
 * Seed All Data - Remplir toutes les tables manquantes
 * AgroSmart CI - Données réalistes pour Côte d'Ivoire
 *
 * Ce script complète les données dans les tables: mesures, alertes, stocks,
 * recommandations, formations, forum posts, ROI tracking, economies, etc.
 * Il utilise les utilisateurs et parcelles existants.
 *
 * Exécution: node scripts/seed-all-data.js
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });

// ============ HELPERS ============

function randomBetween(min, max) {
  return Math.round((Math.random() * (max - min) + min) * 100) / 100;
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomElement(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function daysAgo(days) {
  const d = new Date();
  d.setDate(d.getDate() - days);
  return d;
}

function hoursAgo(hours) {
  const d = new Date();
  d.setHours(d.getHours() - hours);
  return d;
}

// ============ MESURES ============

async function seedMesures(capteurs) {
  console.log('📊 Création des mesures...');
  let count = 0;

  const SENSOR_CONFIG = {
    HUMIDITE_TEMPERATURE_AMBIANTE: {
      values: () => randomBetween(22, 38),
      unite: '°C',
      minNormal: 24,
      maxNormal: 32,
    },
    HUMIDITE_SOL: {
      values: () => randomBetween(25, 85),
      unite: '%',
      minNormal: 40,
      maxNormal: 70,
    },
    UV: {
      values: () => randomBetween(1, 12),
      unite: 'UV',
      minNormal: 2,
      maxNormal: 8,
    },
    NPK: {
      values: () => randomBetween(3, 9),
      unite: 'pH',
      minNormal: 5.5,
      maxNormal: 7.5,
    },
    DIRECTION_VENT: {
      values: () => randomBetween(0, 40),
      unite: 'km/h',
      minNormal: 5,
      maxNormal: 25,
    },
    TRANSPIRATION_PLANTE: {
      values: () => randomBetween(0.5, 5),
      unite: 'mm/h',
      minNormal: 1,
      maxNormal: 3.5,
    },
  };

  // Create 90 days of measurements, every 4 hours
  for (const capteur of capteurs) {
    const config = SENSOR_CONFIG[capteur.type] || SENSOR_CONFIG.HUMIDITE_SOL;
    const mesuresData = [];

    for (let day = 0; day < 90; day++) {
      for (let hour = 0; hour < 24; hour += 4) {
        const timestamp = new Date();
        timestamp.setDate(timestamp.getDate() - day);
        timestamp.setHours(hour, randomInt(0, 59), 0, 0);

        // Add some realistic variation: slightly trending values
        const baseValue = config.values();
        const timeOfDay = hour / 24;
        // Temperature peaks at midday
        let finalValue = baseValue;
        if (capteur.type === 'HUMIDITE_TEMPERATURE_AMBIANTE') {
          finalValue = baseValue + Math.sin(timeOfDay * Math.PI) * 5;
        }
        // Humidity lower at midday
        if (capteur.type === 'HUMIDITE_SOL') {
          finalValue = baseValue - Math.sin(timeOfDay * Math.PI) * 8;
        }

        mesuresData.push({
          capteurId: capteur.id,
          valeur: Math.round(finalValue * 100) / 100,
          unite: config.unite,
          timestamp,
        });
      }
    }

    // Insert in chunks of 200
    for (let i = 0; i < mesuresData.length; i += 200) {
      const chunk = mesuresData.slice(i, i + 200);
      await prisma.mesure.createMany({ data: chunk, skipDuplicates: true });
      count += chunk.length;
    }
  }

  console.log(`   ✅ ${count} mesures créées`);
  return count;
}

// ============ ALERTES ============

async function seedAlertes(users, capteurs) {
  console.log('🚨 Création des alertes...');
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  let count = 0;

  const ALERT_TEMPLATES = [
    // INFO
    { niveau: 'INFO', titre: 'Conditions optimales détectées', message: 'Les conditions de votre parcelle sont idéales pour la croissance de vos cultures. Maintenez les pratiques actuelles.', type: 'condition' },
    { niveau: 'INFO', titre: 'Prévisions météo favorables', message: 'Les prévisions des prochains jours indiquent un temps favorable pour vos activités agricoles.', type: 'meteo' },
    { niveau: 'INFO', titre: 'Rappel de fertilisation', message: 'Il est temps de procéder à la fertilisation de vos parcelles selon le calendrier cultural.', type: 'rappel' },
    { niveau: 'INFO', titre: 'Mesure capteur enregistrée', message: 'Les dernières mesures de vos capteurs ont été enregistrées avec succès.', type: 'capteur' },
    { niveau: 'INFO', titre: 'Nouveau conseil disponible', message: 'Un nouveau conseil agronomique est disponible dans votre espace recommandations.', type: 'conseil' },
    // IMPORTANT
    { niveau: 'IMPORTANT', titre: 'Humidité du sol basse', message: 'L\'humidité du sol de votre parcelle est en dessous du seuil optimal (< 40%). Envisagez l\'irrigation.', type: 'irrigation' },
    { niveau: 'IMPORTANT', titre: 'Température élevée', message: 'La température dépasse 35°C sur votre parcelle. Surveillez vos cultures sensibles à la chaleur.', type: 'temperature' },
    { niveau: 'IMPORTANT', titre: 'Indice UV élevé', message: 'L\'indice UV est élevé aujourd\'hui. Protégez les jeunes plants si nécessaire.', type: 'uv' },
    { niveau: 'IMPORTANT', titre: 'Stock en dessous du seuil', message: 'Le stock d\'engrais est en dessous du seuil minimum. Pensez à réapprovisionner.', type: 'stock' },
    { niveau: 'IMPORTANT', titre: 'Batterie capteur faible', message: 'La batterie d\'un de vos capteurs est inférieure à 20%. Pensez à la recharger ou la remplacer.', type: 'capteur' },
    // CRITIQUE
    { niveau: 'CRITIQUE', titre: 'Alerte sécheresse', message: 'L\'humidité du sol est critique (< 20%). Irrigation urgente nécessaire pour éviter la perte des cultures.', type: 'irrigation' },
    { niveau: 'CRITIQUE', titre: 'Capteur inactif', message: 'Un capteur ne répond plus depuis 24h. Vérifiez l\'installation et la connectivité.', type: 'capteur' },
    { niveau: 'CRITIQUE', titre: 'pH du sol anormal', message: 'Le pH du sol a atteint un niveau critique. Une correction immédiate est recommandée.', type: 'sol' },
  ];

  for (const user of producteurs) {
    const userCapteurs = capteurs.filter(c => {
      // Find capteurs linked to this user's parcelles
      return c.parcelle?.userId === user.id;
    });

    // Create 15-30 alerts per user over the last 60 days
    const numAlerts = randomInt(15, 30);
    for (let i = 0; i < numAlerts; i++) {
      const template = randomElement(ALERT_TEMPLATES);
      const daysBack = randomInt(0, 60);
      const statut = randomElement(['NOUVELLE', 'NOUVELLE', 'LUE', 'LUE', 'TRAITEE', 'IGNOREE']);
      const capteurId = userCapteurs.length > 0 ? randomElement(userCapteurs).id : null;

      await prisma.alerte.create({
        data: {
          userId: user.id,
          capteurId,
          type: template.type,
          niveau: template.niveau,
          titre: template.titre,
          message: template.message,
          statut,
          createdAt: daysAgo(daysBack),
        },
      });
      count++;
    }
  }

  console.log(`   ✅ ${count} alertes créées`);
  return count;
}

// ============ STOCKS ============

async function seedStocks(users) {
  console.log('📦 Création des stocks...');
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  let count = 0;

  const STOCK_TEMPLATES = [
    // SEMENCES
    { nom: 'Semences de Cacao Améliorées', categorie: 'SEMENCES', type: 'Fèves', unite: 'kg', qteRange: [20, 200], prixRange: [5000, 15000], fournisseur: 'CNRA Côte d\'Ivoire' },
    { nom: 'Semences de Café Robusta', categorie: 'SEMENCES', type: 'Cerises', unite: 'kg', qteRange: [10, 150], prixRange: [3000, 8000], fournisseur: 'Pépinière Agricole Daloa' },
    { nom: 'Plants d\'Hévéa greffés', categorie: 'SEMENCES', type: 'Plants', unite: 'unités', qteRange: [50, 500], prixRange: [1500, 3500], fournisseur: 'SAPH CI' },
    { nom: 'Semences de Riz NERICA', categorie: 'SEMENCES', type: 'Grains', unite: 'kg', qteRange: [30, 300], prixRange: [800, 2500], fournisseur: 'ADRAO' },
    // ENGRAIS
    { nom: 'NPK 10-18-18', categorie: 'ENGRAIS', type: 'Chimique', unite: 'kg', qteRange: [50, 1000], prixRange: [350, 650], fournisseur: 'YARA CI' },
    { nom: 'Urée 46%', categorie: 'ENGRAIS', type: 'Chimique', unite: 'kg', qteRange: [25, 500], prixRange: [400, 720], fournisseur: 'YARA CI' },
    { nom: 'Compost organique', categorie: 'ENGRAIS', type: 'Organique', unite: 'kg', qteRange: [100, 2000], prixRange: [100, 300], fournisseur: 'Production locale' },
    { nom: 'Fiente de volaille', categorie: 'ENGRAIS', type: 'Organique', unite: 'sacs', qteRange: [10, 100], prixRange: [2000, 5000], fournisseur: 'Ferme Avicole Bouaké' },
    // PESTICIDES
    { nom: 'Insecticide Biorationnel', categorie: 'PESTICIDES', type: 'Bio', unite: 'litres', qteRange: [5, 50], prixRange: [8000, 18000], fournisseur: 'Syngenta CI' },
    { nom: 'Fongicide Cuivré', categorie: 'PESTICIDES', type: 'Contact', unite: 'kg', qteRange: [3, 30], prixRange: [6000, 15000], fournisseur: 'Bayer CropScience' },
    // HERBICIDES
    { nom: 'Glyphosate 360g/L', categorie: 'HERBICIDES', type: 'Systémique', unite: 'litres', qteRange: [5, 40], prixRange: [5000, 12000], fournisseur: 'Chimie Agric CI' },
    { nom: 'Herbicide sélectif riz', categorie: 'HERBICIDES', type: 'Sélectif', unite: 'litres', qteRange: [2, 20], prixRange: [7000, 16000], fournisseur: 'BASF' },
    // OUTILS
    { nom: 'Machettes renforcées', categorie: 'OUTILS', type: 'Manuel', unite: 'unités', qteRange: [5, 30], prixRange: [2500, 6000], fournisseur: 'Quincaillerie Treichville' },
    { nom: 'Pulvérisateurs 16L', categorie: 'OUTILS', type: 'Équipement', unite: 'unités', qteRange: [1, 5], prixRange: [15000, 45000], fournisseur: 'Agro-Équipement CI' },
    // RECOLTES
    { nom: 'Fèves de Cacao séchées', categorie: 'RECOLTES', type: 'Cacao', unite: 'kg', qteRange: [100, 5000], prixRange: [1000, 1800], fournisseur: null },
    { nom: 'Café vert', categorie: 'RECOLTES', type: 'Café', unite: 'kg', qteRange: [50, 2000], prixRange: [800, 1500], fournisseur: null },
  ];

  for (const user of producteurs) {
    // Get user's parcelles
    const parcelles = await prisma.parcelle.findMany({ where: { userId: user.id }, select: { id: true } });
    const parcelleId = parcelles.length > 0 ? parcelles[0].id : null;

    // 5-10 stocks per user
    const numStocks = randomInt(5, 10);
    const usedTemplates = new Set();

    for (let i = 0; i < numStocks; i++) {
      let template;
      do {
        template = randomElement(STOCK_TEMPLATES);
      } while (usedTemplates.has(template.nom) && usedTemplates.size < STOCK_TEMPLATES.length);
      usedTemplates.add(template.nom);

      const quantite = randomBetween(template.qteRange[0], template.qteRange[1]);
      const seuilAlerte = Math.round(template.qteRange[0] * 1.5);
      const prixUnitaire = randomBetween(template.prixRange[0], template.prixRange[1]);

      const stock = await prisma.stock.create({
        data: {
          userId: user.id,
          parcelleId,
          nom: template.nom,
          categorie: template.categorie,
          type: template.type,
          quantite,
          unite: template.unite,
          seuilAlerte,
          prixUnitaire,
          dateAchat: daysAgo(randomInt(5, 120)),
          dateExpiration: template.categorie !== 'OUTILS' ? new Date(Date.now() + randomInt(90, 365) * 86400000) : null,
          fournisseur: template.fournisseur,
          localisation: `Magasin ${randomElement(['principal', 'secondaire', 'hangar'])}`,
          notes: null,
          estActif: true,
        },
      });

      // Create 2-5 stock movements
      let currentQte = 0;
      const numMouvements = randomInt(2, 5);
      for (let j = 0; j < numMouvements; j++) {
        const typeMouvement = j === 0 ? 'ENTREE' : randomElement(['ENTREE', 'ENTREE', 'SORTIE', 'SORTIE', 'AJUSTEMENT']);
        const qteAvant = currentQte;
        const qteMouvement = randomBetween(template.qteRange[0] * 0.2, template.qteRange[0] * 0.8);

        if (typeMouvement === 'SORTIE' && currentQte <= qteMouvement) {
          currentQte += qteMouvement; // flip to ENTREE silently
          await prisma.mouvementStock.create({
            data: {
              stockId: stock.id,
              typeMouvement: 'ENTREE',
              quantite: qteMouvement,
              quantiteAvant: qteAvant,
              quantiteApres: currentQte,
              motif: randomElement(['Approvisionnement', 'Réception commande', 'Don coopérative']),
              createdAt: daysAgo(randomInt(1, 90)),
            },
          });
        } else {
          if (typeMouvement === 'SORTIE') {
            currentQte -= qteMouvement;
          } else {
            currentQte += qteMouvement;
          }
          await prisma.mouvementStock.create({
            data: {
              stockId: stock.id,
              typeMouvement,
              quantite: qteMouvement,
              quantiteAvant: qteAvant,
              quantiteApres: Math.max(0, currentQte),
              motif: typeMouvement === 'ENTREE'
                ? randomElement(['Approvisionnement', 'Réception commande', 'Don coopérative'])
                : randomElement(['Application parcelle', 'Utilisation terrain', 'Vente partielle']),
              createdAt: daysAgo(randomInt(1, 60)),
            },
          });
        }
      }

      count++;
    }
  }

  console.log(`   ✅ ${count} stocks créés avec mouvements`);
  return count;
}

// ============ RECOMMANDATIONS ============

async function seedRecommandations(users) {
  console.log('💡 Création des recommandations...');
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  let count = 0;

  const RECO_TEMPLATES = [
    // Irrigation
    { type: 'irrigation', titre: 'Irrigation recommandée - Matin', description: 'Les données d\'humidité du sol indiquent un besoin d\'irrigation. Recommandation: 15mm d\'eau par aspersion entre 6h et 8h du matin pour optimiser l\'absorption.', priorite: 2 },
    { type: 'irrigation', titre: 'Réduction d\'irrigation', description: 'Les prévisions météo indiquent des pluies dans les prochaines 48h. Réduisez l\'irrigation de 50% pour éviter le gaspillage d\'eau et l\'engorgement.', priorite: 3 },
    { type: 'irrigation', titre: 'Irrigation d\'urgence', description: 'Le stress hydrique est détecté sur vos plants. Procédez immédiatement à une irrigation de 20mm. Les feuilles montrent des signes de flétrissement.', priorite: 1 },
    // Fertilisation
    { type: 'fertilisation', titre: 'Application d\'engrais NPK', description: 'Le sol montre un déficit en potassium. Appliquez 250g/plant de NPK 10-18-18 en couronne autour des pieds de cacao. Période idéale: début de saison des pluies.', priorite: 2 },
    { type: 'fertilisation', titre: 'Amendement organique', description: 'Le taux de matière organique est bas. Incorporez 2kg de compost par m² pour améliorer la structure du sol et la rétention d\'eau.', priorite: 3 },
    { type: 'fertilisation', titre: 'Correction pH du sol', description: 'Le pH du sol est trop acide (< 5.5). Appliquez 200g/m² de chaux agricole pour remonter le pH à 6.0-6.5, optimal pour le cacao.', priorite: 1 },
    // Protection
    { type: 'protection', titre: 'Traitement préventif Pourriture brune', description: 'Les conditions humides favorisent le développement du Phytophthora. Appliquez un traitement fongicide cuivré en prévention sur les cabosses.', priorite: 2 },
    { type: 'protection', titre: 'Surveillance mirides', description: 'Des traces de piqûres de mirides ont été détectées. Inspectez les cabosses et appliquez un traitement insecticide ciblé si nécessaire.', priorite: 2 },
    { type: 'protection', titre: 'Désherbage nécessaire', description: 'La couverture herbacée dépasse 40cm autour de vos plants. Procédez au désherbage mécanique pour réduire la compétition et les risques sanitaires.', priorite: 3 },
    // Récolte
    { type: 'recolte', titre: 'Récolte à planifier', description: 'Les cabosses sont à maturité dans la section Nord. Planifiez la récolte dans les 5 prochains jours pour obtenir la meilleure qualité de fèves.', priorite: 2 },
    { type: 'recolte', titre: 'Optimisation du séchage', description: 'Après la fermentation, séchez les fèves au soleil pendant 7 jours en retournant régulièrement. Taux d\'humidité cible: 7%.', priorite: 3 },
    // Général
    { type: 'general', titre: 'Ombrage à ajuster', description: 'L\'ombrage dépasse 60% dans certaines zones. Émondez les arbres d\'ombrage pour laisser passer 40-50% de lumière, optimal pour le cacao.', priorite: 3 },
    { type: 'general', titre: 'Planification saison sèche', description: 'Préparez-vous à la saison sèche: constituez une réserve d\'eau, paillez autour des plants, et réduisez les activités de plantation.', priorite: 3 },
  ];

  for (const user of producteurs) {
    const parcelles = await prisma.parcelle.findMany({ where: { userId: user.id }, select: { id: true } });

    // 6-12 recommandations per user
    const numRecos = randomInt(6, 12);
    for (let i = 0; i < numRecos; i++) {
      const template = randomElement(RECO_TEMPLATES);
      const parcelleId = parcelles.length > 0 ? randomElement(parcelles).id : null;
      const createdDaysAgo = randomInt(0, 45);
      const appliquee = Math.random() > 0.6;

      await prisma.recommandation.create({
        data: {
          type: template.type,
          titre: template.titre,
          description: template.description,
          priorite: template.priorite,
          parcelleId,
          userId: user.id,
          generePar: randomElement(['automatique', 'automatique', 'conseiller', 'ia']),
          valideDu: daysAgo(createdDaysAgo),
          valideJusquAu: new Date(Date.now() + randomInt(7, 30) * 86400000),
          appliquee,
          dateApplication: appliquee ? daysAgo(randomInt(0, createdDaysAgo)) : null,
          commentaireUtilisateur: appliquee ? randomElement([
            'Bonne recommandation, résultats visibles.',
            'Appliqué avec succès.',
            'Merci pour le conseil !',
            null,
          ]) : null,
          noteUtilisateur: appliquee ? randomInt(3, 5) : null,
          createdAt: daysAgo(createdDaysAgo),
        },
      });
      count++;
    }
  }

  console.log(`   ✅ ${count} recommandations créées`);
  return count;
}

// ============ FORMATIONS ============

async function seedFormations(users) {
  console.log('📚 Création des formations...');

  const FORMATIONS_DATA = [
    {
      titre: 'Bonnes pratiques de culture du Cacao',
      description: 'Formation complète sur la culture du cacao en Côte d\'Ivoire: choix du terrain, pépinière, plantation, entretien, récolte et post-récolte. Apprenez les techniques qui augmentent vos rendements de 40%.',
      categorie: 'agriculture',
      niveau: 'debutant',
      dureeMinutes: 120,
      modules: [
        { titre: 'Introduction à la cacaoculture en CI', contenu: 'La Côte d\'Ivoire est le premier producteur mondial de cacao avec plus de 2 millions de tonnes par an. Cette formation vous donnera les bases pour réussir votre production.\n\nObjectifs:\n- Comprendre le cycle de vie du cacaoyer\n- Identifier les variétés adaptées à votre région\n- Maîtriser les pratiques de base', ordre: 1 },
        { titre: 'Préparation du sol et pépinière', contenu: 'Le sol idéal pour le cacao:\n- pH entre 6.0 et 7.5\n- Sol profond, bien drainé\n- Riche en matière organique\n\nÉtapes de la pépinière:\n1. Sélection des cabosses mères\n2. Extraction et semis des fèves\n3. Entretien pendant 4-6 mois\n4. Transplantation au champ', ordre: 2 },
        { titre: 'Plantation et ombrage', contenu: 'Densité recommandée: 1111 plants/ha (3m x 3m)\n\nGestion de l\'ombrage:\n- Phase juvénile: 60-70% d\'ombre (bananiers, gliricidia)\n- Phase adulte: 30-40% d\'ombre\n- Émondage régulier des arbres d\'ombrage\n\nAssociation culturale possible la première année: maïs, igname, banane plantain', ordre: 3 },
        { titre: 'Entretien et fertilisation', contenu: 'Calendrier de fertilisation:\n- 1ère année: 100g NPK/plant (2 apports)\n- 2ème-3ème année: 200g NPK/plant\n- Production: 300-400g NPK/plant + 200g Urée\n\nDésherbage:\n- Manuel ou chimique 4x/an\n- Paillage recommandé pour réduire la fréquence', ordre: 4 },
        { titre: 'Récolte et post-récolte', contenu: 'Indicateurs de maturité:\n- Changement de couleur de la cabosse\n- Son mat quand on tape la cabosse\n- Ne pas laisser sur-mûrir\n\nFermentation:\n- 5-7 jours dans des bacs en bois\n- Retourner tous les 2 jours\n- Température: 45-50°C\n\nSéchage:\n- Au soleil pendant 7-14 jours\n- Taux d\'humidité final: 7%', ordre: 5 },
      ],
    },
    {
      titre: 'Gestion de l\'eau et irrigation intelligente',
      description: 'Maîtrisez les techniques d\'irrigation adaptées au climat tropical. Apprenez à utiliser les capteurs IoT pour optimiser votre consommation d\'eau et augmenter vos rendements.',
      categorie: 'irrigation',
      niveau: 'intermediaire',
      dureeMinutes: 90,
      modules: [
        { titre: 'Comprendre les besoins en eau des cultures', contenu: 'Besoins en eau par culture:\n- Cacao: 1500-2500 mm/an\n- Café: 1200-2200 mm/an\n- Hévéa: 2000-3000 mm/an\n- Riz: 1200 mm/cycle\n\nFacteurs influençant les besoins:\n- Température et évapotranspiration\n- Type de sol et capacité de rétention\n- Stade de croissance de la culture', ordre: 1 },
        { titre: 'Systèmes d\'irrigation adaptés', contenu: 'Types d\'irrigation:\n1. Goutte-à-goutte: économie d\'eau 40-60%, idéal pour cacao/café\n2. Aspersion: couverture uniforme, bon pour maraîchage\n3. Gravitaire améliorée: faible coût, adapté riz\n\nCoût d\'installation:\n- Goutte-à-goutte: 500 000 - 1 500 000 FCFA/ha\n- Aspersion: 800 000 - 2 000 000 FCFA/ha', ordre: 2 },
        { titre: 'Utiliser les capteurs IoT', contenu: 'Capteurs disponibles dans AgroSmart:\n- Humidité du sol: placé à 20cm de profondeur\n- Température ambiante: sous abri ventilé\n- Station météo: données vent et pluie\n\nInterpréter les données:\n- Humidité sol < 40%: irrigation nécessaire\n- Humidité sol > 75%: arrêter l\'irrigation\n- Consulter les graphiques dans l\'app Mesures', ordre: 3 },
        { titre: 'Planification et économies d\'eau', contenu: 'Techniques d\'économie d\'eau:\n1. Paillage (réduit évaporation de 30%)\n2. Irrigation nocturne (moins d\'évaporation)\n3. Récupération eau de pluie\n4. Micro-irrigation ciblée\n\nPlanification:\n- Créez un calendrier dans l\'app\n- Suivez les prévisions météo\n- Adaptez selon les alertes des capteurs', ordre: 4 },
      ],
    },
    {
      titre: 'Protection phytosanitaire et lutte biologique',
      description: 'Identifier et combattre les principales maladies et ravageurs du cacao et du café. Privilégier les méthodes biologiques pour une agriculture durable.',
      categorie: 'protection',
      niveau: 'intermediaire',
      dureeMinutes: 150,
      modules: [
        { titre: 'Principales maladies du cacao', contenu: 'Pourriture brune (Phytophthora):\n- Symptômes: taches brunes sur cabosses\n- Favorisée par l\'humidité\n- Perte: jusqu\'à 30% de la récolte\n\nSwollen Shoot:\n- Virus transmis par les cochenilles\n- Gonflement des rameaux\n- Pas de traitement: arracher et replanter\n\nMoniliose:\n- Pourriture blanche des cabosses\n- Récolte sanitaire fréquente', ordre: 1 },
        { titre: 'Ravageurs principaux', contenu: 'Mirides du cacao:\n- Dégâts: piqûres sur cabosses et rameaux\n- Traitement: 2 applications/an en saison sèche\n- Produits bio: neem, pyrèthre naturel\n\nForeurs de tiges:\n- Larves creusent dans les branches\n- Prévention: élagage, destruction des débris\n\nNématodes:\n- Attaquent les racines\n- Utiliser des plants greffés résistants', ordre: 2 },
        { titre: 'Méthodes de lutte biologique', contenu: 'Lutte intégrée (IPM):\n1. Prévention: choix variétal, hygiène parcelle\n2. Observation: inspection hebdomadaire\n3. Seuil d\'intervention: ne traiter que si nécessaire\n\nProduits biologiques:\n- Huile de neem: insecticide naturel\n- Trichoderma: champignon antagoniste\n- Bacillus thuringiensis: contre chenilles\n- Bouillie bordelaise: fongicide autorisé en bio', ordre: 3 },
      ],
    },
    {
      titre: 'Gestion financière de l\'exploitation agricole',
      description: 'Apprenez à gérer les finances de votre exploitation, calculer vos coûts de production, suivre votre ROI et optimiser votre rentabilité avec les outils AgroSmart.',
      categorie: 'gestion',
      niveau: 'debutant',
      dureeMinutes: 60,
      modules: [
        { titre: 'Comptabilité agricole simplifiée', contenu: 'Registres essentiels:\n1. Cahier des dépenses (intrants, main d\'œuvre, équipement)\n2. Cahier des recettes (ventes, subventions)\n3. Inventaire des stocks\n\nCalcul du coût de production:\n- Coûts fixes: amortissement terrain, équipement\n- Coûts variables: engrais, pesticides, main d\'œuvre\n- Coût total / quantité produite = coût unitaire', ordre: 1 },
        { titre: 'Comprendre le ROI agricole', contenu: 'ROI = (Revenus - Coûts) / Coûts × 100\n\nExemple cacao:\n- Investissement: 850 000 FCFA/ha/an\n- Récolte: 800 kg/ha × 1 200 FCFA/kg = 960 000 FCFA\n- ROI = (960 000 - 850 000) / 850 000 × 100 = 12.9%\n\nSuivez votre ROI dans l\'onglet Performance de l\'app.', ordre: 2 },
        { titre: 'Utiliser AgroSmart pour le suivi financier', contenu: 'Fonctionnalités disponibles:\n1. Suivi des stocks et coûts d\'achat\n2. Tableau de bord Performance & ROI\n3. Historique des économies réalisées\n4. Comparaison inter-parcelles\n\nConseils:\n- Enregistrez chaque dépense et recette\n- Consultez les rapports mensuels\n- Comparez vos performances aux moyennes', ordre: 3 },
      ],
    },
    {
      titre: 'Agriculture intelligente avec l\'IoT',
      description: 'Découvrez comment les technologies IoT révolutionnent l\'agriculture en Côte d\'Ivoire. Installation, configuration et utilisation des capteurs connectés.',
      categorie: 'technologie',
      niveau: 'avance',
      dureeMinutes: 180,
      modules: [
        { titre: 'Introduction à l\'IoT agricole', contenu: 'L\'Internet des Objets (IoT) en agriculture:\n- Capteurs connectés mesurant en temps réel\n- Données envoyées automatiquement vers l\'application\n- Alertes intelligentes en cas d\'anomalie\n- Recommandations basées sur les données\n\nBénéfices prouvés:\n- Économie d\'eau: 20-40%\n- Réduction pesticides: 15-30%\n- Augmentation rendements: 10-25%', ordre: 1 },
        { titre: 'Installation des capteurs', contenu: 'Capteur d\'humidité du sol:\n- Profondeur: 15-25cm (zone racinaire)\n- Nombre: 1 par zone homogène (2-3/ha)\n- Orienté vers le nord\n\nStation météo:\n- Hauteur: 1.5m du sol\n- Zone dégagée, pas sous un arbre\n- Portée LoRa: jusqu\'à 2km en terrain dégagé\n\nEntretien:\n- Nettoyage mensuel des sondes\n- Vérification batteries tous les 3 mois\n- Calibrage annuel recommandé', ordre: 2 },
        { titre: 'Analyse des données et prise de décision', contenu: 'Dashboard AgroSmart:\n1. Onglet Mesures: graphiques temps réel\n2. Onglet Capteurs: état de vos équipements\n3. Onglet Alertes: notifications intelligentes\n4. Onglet Recommandations: conseils AI\n\nInterprétation des données:\n- Tendances sur 7/30/90 jours\n- Corrélation température-humidité\n- Seuils personnalisables par culture', ordre: 3 },
        { titre: 'Maintenance et dépannage', contenu: 'Problèmes courants:\n- Capteur hors ligne: vérifier batterie et signal\n- Données aberrantes: recalibrer le capteur\n- Signal faible: repositionner ou ajouter un relai\n\nContact support:\n- Via l\'application: onglet Aide\n- WhatsApp: +225 07 XX XX XX XX\n- Email: support@agrosmart.ci', ordre: 4 },
      ],
    },
    {
      titre: 'Culture du café en zone tropicale',
      description: 'Maîtrisez toutes les étapes de la caféiculture, de la plantation à la tasse. Techniques adaptées au café Robusta en Côte d\'Ivoire.',
      categorie: 'agriculture',
      niveau: 'intermediaire',
      dureeMinutes: 100,
      modules: [
        { titre: 'Introduction au café Robusta', contenu: 'Le café Robusta (Coffea canephora):\n- 2ème espèce de café commercialisé\n- Résistant aux maladies et ravageurs\n- Teneur en caféine: 2-3% (vs 1-1.5% Arabica)\n- Altitude optimale: 0-800m\n- CI: 3ème producteur africain\n\nVariétés recommandées:\n- 126: haute productivité\n- 107: résistant à la trachéomycose\n- 700: qualité tasse supérieure', ordre: 1 },
        { titre: 'Plantation et conduite', contenu: 'Densité: 1333 plants/ha (3m x 2.5m)\n\nConduite:\n- Taille de formation: 1 tige principale + 3-4 ramifications\n- Recépage: tous les 8-10 ans\n- Ombrage: 30-40% (Gliricidia, albizzia)\n\nEau:\n- Besoin: 1200-2200 mm/an\n- Irrigation si saison sèche > 3 mois', ordre: 2 },
        { titre: 'Récolte et transformation', contenu: 'Récolte:\n- Maturité: cerises rouge foncé\n- Cueillette sélective (qualité)\n- Période: Octobre à Janvier en CI\n\nTransformation voie sèche:\n1. Tri des cerises\n2. Séchage au soleil (15-20 jours)\n3. Décorticage mécanique\n4. Triage et calibrage\n5. Mise en sacs (60-65 kg)\n\nStockage: lieu sec, aéré, sur palettes', ordre: 3 },
      ],
    },
  ];

  const formations = [];
  for (const fData of FORMATIONS_DATA) {
    const { modules, ...formationData } = fData;
    const formation = await prisma.formation.create({
      data: {
        ...formationData,
        active: true,
        vues: randomInt(50, 500),
      },
    });

    // Create modules
    for (const moduleData of modules) {
      await prisma.moduleFormation.create({
        data: {
          formationId: formation.id,
          ...moduleData,
        },
      });
    }

    formations.push(formation);
  }

  // Enroll some producteurs
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  let progressionCount = 0;
  for (const user of producteurs) {
    // Each user enrolls in 2-4 formations
    const numEnrolled = randomInt(2, Math.min(4, formations.length));
    const enrolled = [];
    for (let i = 0; i < numEnrolled; i++) {
      let f;
      do {
        f = randomElement(formations);
      } while (enrolled.includes(f.id));
      enrolled.push(f.id);

      const modulesCount = await prisma.moduleFormation.count({ where: { formationId: f.id } });
      const modulesCompleted = randomInt(0, modulesCount);
      const pct = modulesCount > 0 ? Math.round((modulesCompleted / modulesCount) * 100) : 0;

      // Get module IDs
      const modules = await prisma.moduleFormation.findMany({
        where: { formationId: f.id },
        orderBy: { ordre: 'asc' },
        select: { id: true },
      });
      const completedModuleIds = modules.slice(0, modulesCompleted).map(m => m.id);

      await prisma.progressionFormation.create({
        data: {
          userId: user.id,
          formationId: f.id,
          progression: pct,
          complete: pct >= 100,
          modulesTermines: completedModuleIds,
          score: pct >= 100 ? randomInt(70, 100) : null,
          dateDebut: daysAgo(randomInt(10, 90)),
          dateFin: pct >= 100 ? daysAgo(randomInt(0, 10)) : null,
        },
      });
      progressionCount++;
    }
  }

  console.log(`   ✅ ${formations.length} formations créées avec modules`);
  console.log(`   ✅ ${progressionCount} inscriptions/progressions créées`);
  return formations;
}

// ============ FORUM POSTS ============

async function seedForumPosts(users) {
  console.log('💬 Création des posts forum...');
  let postCount = 0;
  let reponseCount = 0;

  const FORUM_POSTS = [
    {
      titre: 'Comment lutter contre la pourriture brune du cacao ?',
      contenu: 'Bonjour à tous,\n\nje suis dans la région de Daloa et cette année j\'ai perdu presque 20% de mes cabosses à cause de la pourriture brune. J\'ai essayé le traitement au cuivre mais ça n\'a pas suffi.\n\nQuels sont vos conseils ? Y a-t-il des méthodes biologiques efficaces ?\n\nMerci d\'avance pour votre aide.',
      categorie: 'maladies',
      reponses: [
        { contenu: 'Salut ! La pourriture brune est un vrai fléau quand la saison des pluies est longue. Ce qui marche bien chez moi:\n1. Récolte sanitaire très fréquente (toutes les 2 semaines)\n2. Traitement fongicide au début des pluies\n3. Amélioration du drainage dans la plantation\n\nCourage, c\'est une bataille qu\'on peut gagner !', estSolution: true },
        { contenu: 'J\'ai le même problème. L\'année dernière j\'ai utilisé du Ridomil et ça a bien fonctionné. Mais cette année je veux essayer des méthodes plus naturelles pour avoir la certification bio.', estSolution: false },
        { contenu: 'Mon conseiller m\'a recommandé de maintenir l\'ombrage à 40% et de bien aérer la plantation. Effectivement depuis que j\'ai éclairci les arbres d\'ombrage, j\'ai moins de pourriture.', estSolution: false },
      ],
    },
    {
      titre: 'Quel engrais utiliser pour le café Robusta ?',
      contenu: 'Bonjour la communauté,\n\nJe viens de planter 2 hectares de café Robusta dans la région de Bouaké. C\'est ma première année et j\'aimerais savoir quel programme de fertilisation vous recommandez.\n\nBudget: environ 200 000 FCFA/ha\n\nMerci pour vos retours.',
      categorie: 'fertilisation',
      reponses: [
        { contenu: 'Pour le café Robusta en première année, je recommande:\n- NPK 10-18-18: 150g/plant en 2 apports (mars et septembre)\n- Urée 46%: 50g/plant en juin\n- Compost: 1kg/plant si possible\n\nAvec ton budget de 200 000 FCFA/ha ça devrait passer. N\'oublie pas le paillage !', estSolution: true },
        { contenu: 'Je suis dans la même région. L\'important c\'est de ne pas trop forcer sur l\'azote la première année, sinon tu auras beaucoup de feuilles mais peu de fruits. Le potassium est plus important pour la fructification.', estSolution: false },
      ],
    },
    {
      titre: 'Installation de capteurs IoT - Retour d\'expérience',
      contenu: 'Bonjour,\n\nJe voulais partager mon expérience avec les capteurs AgroSmart que j\'ai installés il y a 3 mois sur ma plantation de cacao.\n\nPoints positifs:\n- Je vois en temps réel l\'humidité du sol\n- Les alertes m\'ont aidé à mieux gérer l\'irrigation\n- J\'ai économisé environ 30% d\'eau\n\nPoints à améliorer:\n- Le signal est parfois faible dans les zones avec beaucoup d\'arbres\n- La batterie dure environ 4 mois\n\nDans l\'ensemble, je recommande vivement !',
      categorie: 'technologie',
      reponses: [
        { contenu: 'Merci pour ce retour ! J\'hésite à m\'équiper aussi. Tu as combien de capteurs pour quelle surface ?', estSolution: false },
        { contenu: 'J\'ai 4 capteurs pour 3 hectares. Je les ai placés dans les zones les plus stratégiques. L\'application AgroSmart gère tout automatiquement.', estSolution: false },
        { contenu: 'Super retour ! Pour le signal, essaie de placer le gateway en hauteur, sur un poteau de 3m par exemple. Ça améliore beaucoup la portée.', estSolution: true },
        { contenu: 'Moi aussi j\'ai des capteurs depuis 6 mois. L\'économie d\'eau est réelle. Et les recommandations automatiques m\'ont aidé à éviter 2 épisodes de sécheresse qui auraient pu me coûter cher.', estSolution: false },
      ],
    },
    {
      titre: 'Où vendre son cacao au meilleur prix ?',
      contenu: 'La campagne de cacao démarre bientôt. Les années précédentes, les pisteurs offraient 750-800 FCFA/kg. Je cherche des alternatives pour vendre à un meilleur prix.\n\nQui a de l\'expérience avec:\n- La vente directe à des exportateurs?\n- Les coopératives certifiées (Rainforest Alliance, UTZ)?\n- Le marché local de transformation?\n\nMerci pour vos pistes.',
      categorie: 'commercialisation',
      reponses: [
        { contenu: 'Rejoins une coopérative certifiée ! Avec la certification Rainforest Alliance, on touche une prime de 50-80 FCFA/kg en plus du prix garanti. Ça vaut le coup même s\'il y a des exigences à respecter.', estSolution: true },
        { contenu: 'Moi j\'ai essayé la transformation locale (beurre de cacao artisanal). C\'est plus de travail mais je vends à 3000 FCFA/kg au lieu de 800. Si tu as le temps et l\'équipement ça change tout.', estSolution: false },
        { contenu: 'Attention aux pisteurs qui ne respectent pas le prix bord champ fixé par le CCC. Le prix officiel est affiché sur l\'application. En cas de problème, contactez votre coopérative.', estSolution: false },
      ],
    },
    {
      titre: 'Aménagement de parcelle pour l\'hévéa',
      contenu: 'Je souhaite convertir 5 hectares de jachère en plantation d\'hévéa. J\'ai entendu que c\'est rentable à partir de la 7ème année de plantation.\n\nQuestions:\n1. Quel espacement recommandé ?\n2. Comment gérer les 6 premières années sans revenus ?\n3. Quels sont les coûts estimés ?\n\nMerci !',
      categorie: 'plantation',
      reponses: [
        { contenu: 'L\'hévéa est un bon investissement long terme. Espacement: 7m x 3m (476 plants/ha). Pendant les 6 premières années, tu peux faire des cultures intercalaires: maïs, arachide, ou manioc. Ça couvre une partie des frais.', estSolution: true },
        { contenu: 'Budget estimé pour 5 ha:\n- Plants greffés: 1 500 000 FCFA\n- Préparation terrain: 750 000 FCFA\n- Engrais 3 ans: 600 000 FCFA\n- Main d\'œuvre: 500 000 FCFA/an\n\nÀ la saignée (an 7): 1.5 tonnes/ha/an à environ 500 FCFA/kg. ROI positif en 10 ans.', estSolution: false },
      ],
    },
    {
      titre: 'Problème de pH du sol trop acide',
      contenu: 'Bonjour,\n\nMes capteurs NPK montrent un pH de 4.8 sur ma parcelle. C\'est trop acide pour mon cacao (idéal 6.0-7.0).\n\nComment corriger ce problème ? Faut-il du calcaire ou de la chaux ? Quelle quantité ?\n\nMa parcelle fait 1.5 hectares.',
      categorie: 'sol',
      reponses: [
        { contenu: 'pH 4.8 c\'est effectivement trop acide. Tu peux appliquer de la chaux agricole (CaO) ou de la dolomie (CaMg(CO3)2).\n\nPour passer de pH 4.8 à 6.0:\n- Sol sableux: 1-1.5 tonnes/ha\n- Sol argileux: 2-3 tonnes/ha\n\nFais-le en début de saison des pluies pour une meilleure incorporation. Résultat visible en 2-3 mois.', estSolution: true },
        { contenu: 'La dolomie est mieux que la chaux car elle apporte aussi du magnésium. Prix: environ 150 FCFA/kg. Pour 1.5 ha, compte 300 000 à 450 000 FCFA.', estSolution: false },
      ],
    },
    {
      titre: 'Comparaison des systèmes d\'irrigation pour petites parcelles',
      contenu: 'Je cherche un système d\'irrigation pour mes 2 hectares de maraîchage. Budget limité à 500 000 FCFA. Que recommandez-vous entre le goutte-à-goutte et l\'arrosage par aspersion ?\n\nJ\'ai accès à un puits et un petit panneau solaire.',
      categorie: 'irrigation',
      reponses: [
        { contenu: 'Pour du maraîchage sur 2 ha, le goutte-à-goutte est idéal:\n- Économie d\'eau: 40-60%\n- Application uniforme\n- Moins de maladies (pas de mouillage des feuilles)\n\nAvec 500 000 FCFA tu peux équiper 1 ha. Commence par 1 ha et réinvestis les gains.', estSolution: true },
        { contenu: 'Avec le panneau solaire tu peux alimenter une pompe pour le goutte-à-goutte. C\'est ce que j\'ai fait et je ne paie plus de gasoil. Le système se rembourse en 1 saison de tomates.', estSolution: false },
      ],
    },
    {
      titre: 'Gestion de la main d\'œuvre en période de récolte',
      contenu: 'Bonjour,\n\nAvec 8 hectares de cacao, j\'ai besoin de 15-20 travailleurs pendant la grande récolte (octobre-décembre). Mais c\'est de plus en plus difficile de trouver de la main d\'œuvre fiable.\n\nComment gérez-vous ce problème ? Y a-t-il des solutions de mécanisation ?',
      categorie: 'gestion',
      reponses: [
        { contenu: 'Moi j\'organise des groupes d\'entraide avec les planteurs voisins. On se regroupe à 5-6 planteurs et on fait les parcelles à tour de rôle. Ça réduit les coûts et on a assez de monde.', estSolution: false },
        { contenu: 'Pour la mécanisation, il y a maintenant des éclateurs de cabosses mécaniques qui réduisent le besoin en main d\'œuvre de 40%. Coût: environ 150 000 FCFA. Ça vaut l\'investissement à partir de 5 ha.', estSolution: true },
      ],
    },
  ];

  const allUsers = users.filter(u => ['PRODUCTEUR', 'CONSEILLER', 'AGRONOME'].includes(u.role));

  for (const postData of FORUM_POSTS) {
    const auteur = randomElement(allUsers);
    const createdDaysAgo = randomInt(1, 60);

    const post = await prisma.forumPost.create({
      data: {
        auteurId: auteur.id,
        titre: postData.titre,
        contenu: postData.contenu,
        categorie: postData.categorie,
        vues: randomInt(20, 300),
        resolu: postData.reponses.some(r => r.estSolution),
        isActive: true,
        createdAt: daysAgo(createdDaysAgo),
      },
    });
    postCount++;

    // Add responses
    for (const reponseData of postData.reponses) {
      let repondeur;
      do {
        repondeur = randomElement(allUsers);
      } while (repondeur.id === auteur.id && allUsers.length > 1);

      await prisma.forumReponse.create({
        data: {
          postId: post.id,
          auteurId: repondeur.id,
          contenu: reponseData.contenu,
          estSolution: reponseData.estSolution,
          upvotes: randomInt(0, 15),
          createdAt: daysAgo(randomInt(0, createdDaysAgo)),
        },
      });
      reponseCount++;
    }
  }

  console.log(`   ✅ ${postCount} posts forum créés`);
  console.log(`   ✅ ${reponseCount} réponses créées`);
}

// ============ PLANTATIONS & RECOLTES ============

async function seedPlantationsRecoltes(users) {
  console.log('🌱 Création des plantations et récoltes...');
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  let plantCount = 0;
  let recolteCount = 0;

  for (const user of producteurs) {
    const parcelles = await prisma.parcelle.findMany({
      where: { userId: user.id },
      select: { id: true, superficie: true, cultureActuelle: true },
    });

    // Get available cultures
    const cultures = await prisma.culture.findMany({ select: { id: true, nom: true } });
    if (cultures.length === 0) continue;

    for (const parcelle of parcelles) {
      // Find matching culture for parcelle's current culture
      let cultureId;
      if (parcelle.cultureActuelle) {
        const matched = cultures.find(c => c.nom.toLowerCase().includes(parcelle.cultureActuelle.toLowerCase()));
        cultureId = matched?.id || cultures[0].id;
      } else {
        cultureId = randomElement(cultures).id;
      }

      // Create 1-2 plantations per parcelle
      const numPlantations = randomInt(1, 2);
      for (let p = 0; p < numPlantations; p++) {
        const datePlantation = daysAgo(randomInt(120, 730));

        const plantation = await prisma.plantation.create({
          data: {
            parcelleId: parcelle.id,
            cultureId,
            datePlantation,
            statut: 'active',
            quantitePlantee: randomBetween(50, 500),
            rendementParHectare: randomBetween(400, 1200),
            estActive: true,
          },
        });
        plantCount++;

        // Create 1-3 harvests per plantation
        const numRecoltes = randomInt(1, 3);
        for (let r = 0; r < numRecoltes; r++) {
          const dateRecolte = new Date(datePlantation.getTime() + randomInt(90, 365) * 86400000);
          if (dateRecolte > new Date()) continue;

          await prisma.recolte.create({
            data: {
              plantationId: plantation.id,
              quantiteKg: randomBetween(100, 3000),
              rendementParHectare: randomBetween(300, 1200),
              qualite: randomElement(['Excellente', 'Bonne', 'Moyenne', 'Bonne', 'Excellente']),
              dateRecolte,
              notes: randomElement([
                'Bonne récolte cette saison.',
                'Rendement impacté par la sécheresse.',
                'Qualité supérieure, bien fermenté.',
                'Saison favorable, bon résultat.',
                null,
              ]),
            },
          });
          recolteCount++;
        }
      }
    }
  }

  console.log(`   ✅ ${plantCount} plantations créées`);
  console.log(`   ✅ ${recolteCount} récoltes créées`);
}

// ============ ROI TRACKING ============

async function seedRoiTracking(users) {
  console.log('📈 Création des données ROI...');
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  let count = 0;

  for (const user of producteurs) {
    const parcelles = await prisma.parcelle.findMany({
      where: { userId: user.id },
      select: { id: true },
    });

    // Create ROI data for last 4 quarters
    for (let q = 0; q < 4; q++) {
      const periodeFin = new Date();
      periodeFin.setMonth(periodeFin.getMonth() - q * 3);
      const periodeDebut = new Date(periodeFin);
      periodeDebut.setMonth(periodeDebut.getMonth() - 3);

      const parcelleId = parcelles.length > 0 ? randomElement(parcelles).id : null;

      const coutSemences = randomBetween(50000, 300000);
      const coutEngrais = randomBetween(100000, 500000);
      const coutPesticides = randomBetween(30000, 200000);
      const coutIrrigation = randomBetween(20000, 150000);
      const coutMainOeuvre = randomBetween(100000, 400000);
      const autresCouts = randomBetween(10000, 80000);
      const totalCouts = coutSemences + coutEngrais + coutPesticides + coutIrrigation + coutMainOeuvre + autresCouts;

      const quantiteRecoltee = randomBetween(200, 2000);
      const prixVenteUnitaire = randomBetween(750, 1500);
      const revenus = quantiteRecoltee * prixVenteUnitaire;
      const roi = ((revenus - totalCouts) / totalCouts) * 100;

      await prisma.roiTracking.create({
        data: {
          userId: user.id,
          parcelleId,
          periodeDebut,
          periodeFin,
          coutSemences,
          coutEngrais,
          coutPesticides,
          coutIrrigation,
          coutMainOeuvre,
          autresCouts,
          quantiteRecoltee,
          prixVenteUnitaire,
          roiTrend: roi > 15 ? 'hausse' : roi > 0 ? 'stable' : 'baisse',
        },
      });
      count++;
    }
  }

  console.log(`   ✅ ${count} entrées ROI créées`);
}

// ============ ECONOMIES ============

async function seedEconomies(users) {
  console.log('💰 Création des données d\'économies...');
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  let count = 0;

  for (const user of producteurs) {
    // Create monthly economy records for last 6 months
    for (let m = 0; m < 6; m++) {
      const dateFin = new Date();
      dateFin.setMonth(dateFin.getMonth() - m);
      const dateDebut = new Date(dateFin);
      dateDebut.setMonth(dateDebut.getMonth() - 1);

      const eauPct = randomBetween(10, 40);
      const engraisPct = randomBetween(5, 25);
      const pertesPct = randomBetween(8, 35);

      const valeurEau = randomBetween(15000, 80000);
      const valeurEngrais = randomBetween(20000, 100000);
      const valeurPertes = randomBetween(25000, 150000);

      await prisma.economies.create({
        data: {
          userId: user.id,
          eauEconomiseePourcentage: eauPct,
          engraisEconomisePourcentage: engraisPct,
          pertesEviteesPourcentage: pertesPct,
          valeurEauEconomiseeFcfa: valeurEau,
          valeurEngraisEconomiseFcfa: valeurEngrais,
          valeurPertesEviteesFcfa: valeurPertes,
          economiesTotalesFcfa: valeurEau + valeurEngrais + valeurPertes,
          dateDebut,
          dateFin,
        },
      });
      count++;
    }
  }

  console.log(`   ✅ ${count} entrées d'économies créées`);
}

// ============ PERFORMANCE PARCELLES ============

async function seedPerformanceParcelles(users) {
  console.log('🏆 Création des performances parcelles...');
  const producteurs = users.filter(u => u.role === 'PRODUCTEUR');
  let perfCount = 0;
  let rendCount = 0;

  const currentYear = new Date().getFullYear();

  for (const user of producteurs) {
    const parcelles = await prisma.parcelle.findMany({
      where: { userId: user.id },
      select: { id: true },
    });

    const cultures = await prisma.culture.findMany({ select: { id: true } });

    for (const parcelle of parcelles) {
      // Performance for last 2 years
      for (let y = 0; y < 2; y++) {
        const annee = currentYear - y;

        try {
          await prisma.performanceParcelle.create({
            data: {
              userId: user.id,
              parcelleId: parcelle.id,
              annee,
              rendementMoyen: randomBetween(400, 1200),
              scoreQualiteSol: randomBetween(55, 95),
              meilleurePratique: randomElement([
                'Paillage organique et fertilisation raisonnée',
                'Irrigation goutte-à-goutte et ombrage optimal',
                'Association culturale et rotation des parcelles',
                'Compostage et lutte biologique intégrée',
              ]),
            },
          });
          perfCount++;
        } catch (e) {
          // Skip duplicates (unique constraint on parcelleId+annee)
        }

        // Rendement par culture
        if (cultures.length > 0) {
          const cultureId = randomElement(cultures).id;
          try {
            await prisma.rendementParCulture.create({
              data: {
                parcelleId: parcelle.id,
                cultureId,
                annee,
                rendementKgHa: randomBetween(300, 1500),
                qualite: randomElement(['Excellente', 'Bonne', 'Moyenne']),
                notes: randomElement([
                  'Saison favorable',
                  'Impact sécheresse modéré',
                  'Bon résultat avec irrigation',
                  null,
                ]),
              },
            });
            rendCount++;
          } catch (e) {
            // Skip duplicates (unique constraint on parcelleId+cultureId+annee)
          }
        }
      }
    }
  }

  console.log(`   ✅ ${perfCount} performances parcelles créées`);
  console.log(`   ✅ ${rendCount} rendements par culture créés`);
}

// ============ MAIN ============

async function main() {
  console.log('');
  console.log('🌾 ====================================');
  console.log('   SEED ALL DATA - AgroSmart CI');
  console.log('   Remplissage complet de la base');
  console.log('🌾 ====================================');
  console.log('');

  try {
    // Fetch existing data
    const users = await prisma.user.findMany({
      select: { id: true, role: true, nom: true },
    });
    console.log(`👥 ${users.length} utilisateurs trouvés`);

    if (users.length === 0) {
      console.error('❌ Aucun utilisateur trouvé ! Exécutez d\'abord seed-complete.js');
      process.exit(1);
    }

    const parcelles = await prisma.parcelle.findMany({
      select: { id: true, userId: true, nom: true, superficie: true, cultureActuelle: true },
    });
    console.log(`🏞️  ${parcelles.length} parcelles trouvées`);

    const capteurs = await prisma.capteur.findMany({
      include: {
        station: {
          include: {
            parcelle: { select: { userId: true } },
          },
        },
      },
    });
    // Flatten for easy access
    const capteursWithUser = capteurs.map(c => ({
      ...c,
      parcelle: c.station?.parcelle || null,
    }));
    console.log(`📡 ${capteurs.length} capteurs trouvés`);
    console.log('');

    // Check what already exists and skip if needed
    const existingMesures = await prisma.mesure.count();
    const existingAlertes = await prisma.alerte.count();
    const existingStocks = await prisma.stock.count();
    const existingRecos = await prisma.recommandation.count();
    const existingFormations = await prisma.formation.count();
    const existingPosts = await prisma.forumPost.count();
    const existingRoi = await prisma.roiTracking.count();
    const existingEconomies = await prisma.economies.count();
    const existingPerf = await prisma.performanceParcelle.count();
    const existingPlantations = await prisma.plantation.count();

    if (existingMesures < 100 && capteursWithUser.length > 0) {
      await seedMesures(capteursWithUser);
    } else {
      console.log(`⏭️  Mesures déjà présentes (${existingMesures})`);
    }

    if (existingAlertes < 10) {
      await seedAlertes(users, capteursWithUser);
    } else {
      console.log(`⏭️  Alertes déjà présentes (${existingAlertes})`);
    }

    if (existingStocks < 5) {
      await seedStocks(users);
    } else {
      console.log(`⏭️  Stocks déjà présents (${existingStocks})`);
    }

    if (existingRecos < 5) {
      await seedRecommandations(users);
    } else {
      console.log(`⏭️  Recommandations déjà présentes (${existingRecos})`);
    }

    if (existingFormations < 3) {
      await seedFormations(users);
    } else {
      console.log(`⏭️  Formations déjà présentes (${existingFormations})`);
    }

    if (existingPosts < 3) {
      await seedForumPosts(users);
    } else {
      console.log(`⏭️  Posts forum déjà présents (${existingPosts})`);
    }

    if (existingPlantations < 5) {
      await seedPlantationsRecoltes(users);
    } else {
      console.log(`⏭️  Plantations déjà présentes (${existingPlantations})`);
    }

    if (existingRoi < 5) {
      await seedRoiTracking(users);
    } else {
      console.log(`⏭️  ROI tracking déjà présent (${existingRoi})`);
    }

    if (existingEconomies < 5) {
      await seedEconomies(users);
    } else {
      console.log(`⏭️  Économies déjà présentes (${existingEconomies})`);
    }

    if (existingPerf < 5) {
      await seedPerformanceParcelles(users);
    } else {
      console.log(`⏭️  Performances déjà présentes (${existingPerf})`);
    }

    console.log('');
    console.log('✅ ====================================');
    console.log('   SEED TERMINÉ AVEC SUCCÈS !');
    console.log('   Toutes les tables sont remplies.');
    console.log('✅ ====================================');

  } catch (error) {
    console.error('❌ Erreur lors du seed:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

main();
