/**
 * Script de seed pour les capteurs et mesures IoT
 * Génère des données de test réalistes pour le système de monitoring
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });

// Types de capteurs avec leurs paramètres
const CAPTEUR_CONFIGS = {
  HUMIDITE_SOL: {
    unite: '%',
    seuilMin: 20,
    seuilMax: 80,
    valeurTypique: 50,
    variation: 15
  },
  HUMIDITE_TEMPERATURE_AMBIANTE: {
    // Utilisé pour la température
    unite: '°C',
    seuilMin: 15,
    seuilMax: 35,
    valeurTypique: 25,
    variation: 5
  },
  NPK: {
    // Pour Azote, Phosphore, Potassium
    unite: 'ppm',
    seuilMin: 30,
    seuilMax: 100,
    valeurTypique: 60,
    variation: 20
  },
  UV: {
    unite: 'UV Index',
    seuilMin: 0,
    seuilMax: 11,
    valeurTypique: 6,
    variation: 3
  },
  DIRECTION_VENT: {
    unite: '°',
    seuilMin: 0,
    seuilMax: 360,
    valeurTypique: 180,
    variation: 180
  },
  TRANSPIRATION_PLANTE: {
    unite: 'ml/h',
    seuilMin: 0,
    seuilMax: 10,
    valeurTypique: 3,
    variation: 2
  }
};

/**
 * Générer une valeur aléatoire dans une plage
 */
function randomValue(min, max) {
  return Math.random() * (max - min) + min;
}

/**
 * Générer une valeur réaliste pour un type de capteur
 */
function generateMeasurement(config, timestamp) {
  const base = config.valeurTypique;
  const variation = config.variation;
  
  // Ajouter une variation circadienne pour température et UV
  let circadianFactor = 0;
  if (config.unite === '°C' || config.unite === 'UV Index') {
    const hour = timestamp.getHours();
    // Plus chaud/lumineux entre 11h et 16h
    circadianFactor = Math.sin((hour - 6) * Math.PI / 12) * variation * 0.5;
  }
  
  const value = base + circadianFactor + randomValue(-variation, variation);
  return Math.max(config.seuilMin, Math.min(config.seuilMax, value));
}

/**
 * Créer des capteurs pour une parcelle
 */
async function createCapteursForParcelle(parcelle) {
  console.log(`\n📡 Création des capteurs pour ${parcelle.nom}...`);
  
  const capteurs = [];
  
  // 1. Capteur d'humidité du sol
  capteurs.push({
    parcelleId: parcelle.id,
    nom: 'Humidité du Sol',
    type: 'HUMIDITE_SOL',
    unite: CAPTEUR_CONFIGS.HUMIDITE_SOL.unite,
    seuilMin: CAPTEUR_CONFIGS.HUMIDITE_SOL.seuilMin,
    seuilMax: CAPTEUR_CONFIGS.HUMIDITE_SOL.seuilMax,
    statut: 'ACTIF',
    signal: Math.floor(randomValue(70, 100)),
    batterie: Math.floor(randomValue(60, 100))
  });
  
  // 2. Capteur de température ambiante
  capteurs.push({
    parcelleId: parcelle.id,
    nom: 'Température Ambiante',
    type: 'HUMIDITE_TEMPERATURE_AMBIANTE',
    unite: CAPTEUR_CONFIGS.HUMIDITE_TEMPERATURE_AMBIANTE.unite,
    seuilMin: CAPTEUR_CONFIGS.HUMIDITE_TEMPERATURE_AMBIANTE.seuilMin,
    seuilMax: CAPTEUR_CONFIGS.HUMIDITE_TEMPERATURE_AMBIANTE.seuilMax,
    statut: 'ACTIF',
    signal: Math.floor(randomValue(70, 100)),
    batterie: Math.floor(randomValue(60, 100))
  });
  
  // 3. Capteurs NPK (Azote, Phosphore, Potassium)
  const npkElements = [
    { nom: 'Azote (N)', seuilMin: 40, seuilMax: 100 },
    { nom: 'Phosphore (P)', seuilMin: 30, seuilMax: 80 },
    { nom: 'Potassium (K)', seuilMin: 35, seuilMax: 90 }
  ];
  
  for (const element of npkElements) {
    capteurs.push({
      parcelleId: parcelle.id,
      nom: element.nom,
      type: 'NPK',
      unite: CAPTEUR_CONFIGS.NPK.unite,
      seuilMin: element.seuilMin,
      seuilMax: element.seuilMax,
      statut: 'ACTIF',
      signal: Math.floor(randomValue(70, 100)),
      batterie: Math.floor(randomValue(60, 100))
    });
  }
  
  // 4. Capteur UV
  capteurs.push({
    parcelleId: parcelle.id,
    nom: 'Rayonnement UV',
    type: 'UV',
    unite: CAPTEUR_CONFIGS.UV.unite,
    seuilMin: CAPTEUR_CONFIGS.UV.seuilMin,
    seuilMax: CAPTEUR_CONFIGS.UV.seuilMax,
    statut: 'ACTIF',
    signal: Math.floor(randomValue(70, 100)),
    batterie: Math.floor(randomValue(60, 100))
  });
  
  // Créer tous les capteurs
  const createdCapteurs = [];
  for (const capteurData of capteurs) {
    const capteur = await prisma.capteur.create({
      data: capteurData
    });
    createdCapteurs.push(capteur);
    console.log(`  ✓ Capteur créé: ${capteur.nom} (${capteur.type})`);
  }
  
  return createdCapteurs;
}

/**
 * Générer des mesures historiques pour un capteur
 */
async function generateMesuresForCapteur(capteur, daysBack = 7) {
  console.log(`  📊 Génération de mesures pour ${capteur.nom}...`);
  
  const config = CAPTEUR_CONFIGS[capteur.type];
  const mesures = [];
  
  const now = new Date();
  const intervalsPerDay = 24; // Une mesure par heure
  const totalIntervals = daysBack * intervalsPerDay;
  
  for (let i = 0; i < totalIntervals; i++) {
    const timestamp = new Date(now - (i * 60 * 60 * 1000)); // Remonter d'une heure à chaque fois
    const valeur = generateMeasurement(config, timestamp);
    
    mesures.push({
      capteurId: capteur.id,
      valeur: valeur,
      unite: capteur.unite,
      timestamp: timestamp
    });
  }
  
  // Créer les mesures en batch
  await prisma.mesure.createMany({
    data: mesures
  });
  
  console.log(`    ✓ ${mesures.length} mesures générées`);
  return mesures.length;
}

/**
 * Script principal
 */
async function main() {
  console.log('🌱 Seed des capteurs et mesures IoT\n');
  
  try {
    // Récupérer toutes les parcelles
    const parcelles = await prisma.parcelle.findMany({
      take: 5 // Limiter aux 5 premières parcelles pour le test
    });
    
    if (parcelles.length === 0) {
      console.log('❌ Aucune parcelle trouvée. Veuillez d\'abord créer des parcelles.');
      return;
    }
    
    console.log(`✓ ${parcelles.length} parcelles trouvées\n`);
    
    let totalCapteurs = 0;
    let totalMesures = 0;
    
    // Pour chaque parcelle
    for (const parcelle of parcelles) {
      // Créer les capteurs
      const capteurs = await createCapteursForParcelle(parcelle);
      totalCapteurs += capteurs.length;
      
      // Générer des mesures pour chaque capteur
      for (const capteur of capteurs) {
        const count = await generateMesuresForCapteur(capteur, 7); // 7 jours d'historique
        totalMesures += count;
      }
    }
    
    console.log('\n✅ Seed terminé avec succès!');
    console.log(`   📡 ${totalCapteurs} capteurs créés`);
    console.log(`   📊 ${totalMesures} mesures générées`);
    
  } catch (error) {
    console.error('❌ Erreur lors du seed:', error);
    throw error;
  }
}

// Exécuter le script
main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
