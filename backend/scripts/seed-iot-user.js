const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });

async function seedIotForUser(userId) {
  console.log(`\n🌱 Génération IoT pour utilisateur ${userId}\n`);

  // Récupérer les parcelles de l'utilisateur
  const parcelles = await prisma.parcelle.findMany({
    where: { userId },
    select: { 
      id: true, 
      nom: true,
      superficie: true,
      cultureActuelle: true 
    }
  });

  console.log(`✓ ${parcelles.length} parcelles trouvées:`);
  parcelles.forEach(p => {
    console.log(`  - ${p.nom} (${p.superficie} ha, ${p.cultureActuelle || 'culture non définie'})`);
  });

  let totalCapteurs = 0;
  let totalMesures = 0;

  for (const parcelle of parcelles) {
    console.log(`\n📡 Création capteurs pour "${parcelle.nom}"...`);

    // Créer une station météo pour la parcelle
    const station = await prisma.station.create({
      data: {
        nom: `Station ${parcelle.nom}`,
        modele: 'AgriSmart Pro v2',
        statut: 'ACTIVE',
        parcelleId: parcelle.id,
        latitude: -5.5471 + (Math.random() - 0.5) * 0.1, // Région d'Abidjan ±5km
        longitude: -4.0388 + (Math.random() - 0.5) * 0.1,
        batterie: 85 + Math.floor(Math.random() * 15), // 85-100%
        signal: 70 + Math.floor(Math.random() * 30) // 70-100%
      }
    });

    console.log(`  ✓ Station créée: ${station.nom} (${station.id})`);

    // Types de capteurs agricoles
    const capteurTypes = [
      { 
        type: 'HUMIDITE_SOL', 
        nom: 'Humidité Sol', 
        unite: '%', 
        min: 20, 
        max: 80,
        valeurBase: 45 // Valeur moyenne
      },
      { 
        type: 'HUMIDITE_TEMPERATURE_AMBIANTE', 
        nom: 'Température Ambiante', 
        unite: '°C', 
        min: 18, 
        max: 38,
        valeurBase: 27
      },
      { 
        type: 'NPK', 
        nom: 'Azote (N)', 
        unite: 'mg/kg', 
        min: 10, 
        max: 200,
        valeurBase: 80
      },
      { 
        type: 'NPK', 
        nom: 'Phosphore (P)', 
        unite: 'mg/kg', 
        min: 10, 
        max: 200,
        valeurBase: 65
      },
      { 
        type: 'NPK', 
        nom: 'Potassium (K)', 
        unite: 'mg/kg', 
        min: 10, 
        max: 200,
        valeurBase: 95
      },
      { 
        type: 'UV', 
        nom: 'Indice UV', 
        unite: 'index', 
        min: 0, 
        max: 11,
        valeurBase: 6
      }
    ];

    let capteursCreated = 0;

    for (const capteurDef of capteurTypes) {
      const capteur = await prisma.capteur.create({
        data: {
          nom: capteurDef.nom,
          type: capteurDef.type,
          unite: capteurDef.unite,
          seuilMin: capteurDef.min,
          seuilMax: capteurDef.max,
          statut: 'ACTIF',
          stationId: station.id,
          parcelleId: parcelle.id,
          signal: 70 + Math.floor(Math.random() * 30), // 70-100%
          batterie: 60 + Math.floor(Math.random() * 40) // 60-100%
        }
      });

      capteursCreated++;

      // Générer 168 mesures (7 jours x 24h)
      const now = new Date();
      let mesuresCreated = 0;

      for (let jour = 6; jour >= 0; jour--) {
        for (let heure = 0; heure < 24; heure++) {
          const timestamp = new Date(now);
          timestamp.setDate(timestamp.getDate() - jour);
          timestamp.setHours(heure, Math.floor(Math.random() * 60), 0, 0);

          let valeur;
          
          // Générer des valeurs réalistes selon le type
          if (capteurDef.type === 'HUMIDITE_SOL') {
            // Variation jour/nuit + tendance hebdomadaire
            const heureVariation = (heure >= 6 && heure <= 18) ? -5 : 5; // Plus sec le jour
            const jourVariation = jour * 2; // Diminue avec le temps (besoin d'arrosage)
            valeur = capteurDef.valeurBase + heureVariation - jourVariation + (Math.random() - 0.5) * 10;
            valeur = Math.max(capteurDef.min, Math.min(capteurDef.max, valeur));
            
          } else if (capteurDef.type === 'HUMIDITE_TEMPERATURE_AMBIANTE') {
            // Variation jour/nuit
            const heureVariation = heure < 6 ? -5 : (heure > 18 ? -3 : (heure >= 12 && heure <= 15 ? 8 : 3));
            valeur = capteurDef.valeurBase + heureVariation + (Math.random() - 0.5) * 3;
            valeur = Math.max(capteurDef.min, Math.min(capteurDef.max, valeur));
            
          } else if (capteurDef.type === 'NPK') {
            // NPK varie lentement (absorption plantes + apports)
            const jourVariation = jour * -0.5; // Légère diminution
            valeur = capteurDef.valeurBase + jourVariation + (Math.random() - 0.5) * 15;
            valeur = Math.max(capteurDef.min, Math.min(capteurDef.max, valeur));
            
          } else if (capteurDef.type === 'UV') {
            // UV élevé entre 10h et 16h
            if (heure >= 10 && heure <= 16) {
              valeur = 7 + Math.floor(Math.random() * 4); // 7-10
            } else if (heure >= 7 && heure <= 18) {
              valeur = 3 + Math.floor(Math.random() * 4); // 3-6
            } else {
              valeur = 0; // Nuit
            }
          }

          // Valeur arrondie
          const valeurFinale = Math.round(valeur * 100) / 100;

          await prisma.mesure.create({
            data: {
              valeur: valeurFinale, // 2 décimales
              timestamp,
              unite: capteurDef.unite,
              capteurId: capteur.id
            }
          });

          mesuresCreated++;
        }
      }

      totalMesures += mesuresCreated;
      console.log(`    ✓ ${capteurDef.nom}: ${mesuresCreated} mesures`);
    }

    totalCapteurs += capteursCreated;
    console.log(`  📊 Total parcelle: ${capteursCreated} capteurs, ${capteursCreated * 168} mesures`);
  }

  console.log(`\n✅ Seed IoT terminé !`);
  console.log(`   📡 ${totalCapteurs} capteurs créés`);
  console.log(`   📊 ${totalMesures} mesures générées`);
  console.log(`   🌾 ${parcelles.length} parcelles équipées\n`);
}

// Exécuter pour l'utilisateur Yao Koné (0700000002)
const USER_ID = 'd50ff5cc-3c8a-4d8e-bed7-4ffb73795597';

console.log('╔════════════════════════════════════════════════════╗');
console.log('║   🌾 SEED IoT - UTILISATEUR SPÉCIFIQUE           ║');
console.log('╚════════════════════════════════════════════════════╝');

seedIotForUser(USER_ID)
  .then(() => {
    console.log('🎉 Script terminé avec succès !');
    prisma.$disconnect();
    process.exit(0);
  })
  .catch((e) => {
    console.error('❌ Erreur lors du seed :');
    console.error(e);
    prisma.$disconnect();
    process.exit(1);
  });
