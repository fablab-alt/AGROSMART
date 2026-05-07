/**
 * Script de Seed - Données de démonstration
 * Agrosmart CI - Système Agricole Intelligent
 */

const db = require('../src/config/database');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

async function seed() {
  console.log('🌱 Démarrage du seed...\n');
  try {
    // Vérifier l'instance DB
    const dbInfo = await db.query('SELECT version()');
    console.log('🖥️ Info DB:', dbInfo.rows[0]);

    // Nettoyer la base de données
    console.log('🧹 Nettoyage de la base de données...');
    await db.query('SET FOREIGN_KEY_CHECKS = 0');
    await db.query('TRUNCATE TABLE users');
    await db.query('TRUNCATE TABLE parcelles');
    await db.query('TRUNCATE TABLE stations');
    await db.query('TRUNCATE TABLE capteurs');
    await db.query('TRUNCATE TABLE mesures');
    await db.query('TRUNCATE TABLE cultures');
    await db.query('TRUNCATE TABLE maladies');
    await db.query('TRUNCATE TABLE formations');
    await db.query('TRUNCATE TABLE marketplace_produits');
    await db.query('TRUNCATE TABLE diagnostics');
    await db.query('SET FOREIGN_KEY_CHECKS = 1');

    // Créer les utilisateurs de démonstration
    console.log('👤 Création des utilisateurs...');
    const hashedPassword = await bcrypt.hash('password123', 12);

    const users = [
      {
        id: uuidv4(),
        telephone: '+2250101010101',
        email: 'admin@agrosmart.ci',
        nom: 'Kouassi',
        prenom: 'Admin',
        role: 'ADMIN',
        localisation: 'Abidjan'
      },
      {
        id: uuidv4(),
        telephone: '+2250102020202',
        email: 'conseiller@agrosmart.ci',
        nom: 'Koné',
        prenom: 'Ibrahim',
        role: 'CONSEILLER',
        localisation: 'Bouaké'
      },
      {
        id: uuidv4(),
        telephone: '+2250103030303',
        email: 'producteur1@agrosmart.ci',
        nom: 'Tra',
        prenom: 'Bi',
        role: 'PRODUCTEUR',
        localisation: 'Daloa'
      },
      {
        id: uuidv4(),
        telephone: '+2250104040404',
        email: 'producteur2@agrosmart.ci',
        nom: 'Yao',
        prenom: 'Kouadio',
        role: 'PRODUCTEUR',
        localisation: 'Yamoussoukro'
      }
    ];

    for (const user of users) {
      await db.query(`
        INSERT IGNORE INTO users (id, telephone, email, password_hash, nom, prenoms, role)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `, [user.id, user.telephone, user.email, hashedPassword, user.nom, user.prenom, user.role]);
    }
    console.log(`   ✅ ${users.length} utilisateurs créés`);

    // Récupérer les IDs des producteurs
    const producteurs = await db.query(`SELECT id FROM users WHERE role = 'PRODUCTEUR'`);

    // Créer des produits marketplace
    console.log('\n🛒 Création des produits marketplace...');
    const produits = [
      { nom: 'Mangues Kent', categorie: 'fruit', unite: 'kg', prix: 800, stock: 120, description: 'Mangues fraîches de saison' },
      { nom: 'Tomates fraîches', categorie: 'legume', unite: 'kg', prix: 600, stock: 200, description: 'Tomates bio récoltées du jour' },
      { nom: 'Riz local', categorie: 'cereale', unite: 'kg', prix: 900, stock: 500, description: 'Riz local de qualité supérieure' },
      { nom: 'Igname', categorie: 'tubercule', unite: 'kg', prix: 700, stock: 150, description: 'Igname fraîchement récoltée' },
      { nom: 'Piment', categorie: 'legume', unite: 'kg', prix: 1200, stock: 80, description: 'Piment fort' },
      { nom: 'Banane plantain', categorie: 'fruit', unite: 'kg', prix: 500, stock: 180, description: 'Plantain mûr' }
    ];

    let produitCount = 0;
    for (let i = 0; i < produits.length; i++) {
      const vendeur = producteurs.rows[i % producteurs.rows.length];
      const item = produits[i];

      await db.query(
        `INSERT IGNORE INTO marketplace_produits
          (id, vendeur_id, nom, description, categorie, prix, unite, stock, images, type_offre, actif, is_active)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'vente', 1, 1)`,
        [
          uuidv4(),
          vendeur.id,
          item.nom,
          item.description,
          item.categorie,
          item.prix,
          item.unite,
          item.stock,
          JSON.stringify([])
        ]
      );
      produitCount++;
    }
    console.log(`   ✅ ${produitCount} produits marketplace créés`);

    // Créer des parcelles
    console.log('\n🌾 Création des parcelles...');

    const parcelles = [];
    for (let i = 0; i < 20; i++) {
      const parcelleId = uuidv4();
      parcelles.push(parcelleId);

      await db.query(`
        INSERT IGNORE INTO parcelles (id, user_id, nom, superficie, type_sol, statut)
        VALUES (?, ?, ?, ?, ?, 'ACTIVE')
      `, [
        parcelleId,
        producteurs.rows[i % producteurs.rows.length].id,
        `Parcelle ${i + 1} - ${['Cacao', 'Café', 'Hévéa'][i % 3]}`,
        (Math.random() * 5 + 1).toFixed(2),
        ['argileux', 'sablonneux', 'limoneux'][i % 3]
      ]);
    }
    console.log(`   ✅ ${parcelles.length} parcelles créées`);

    // Créer des stations et capteurs
    console.log('\n📡 Création des stations et capteurs...');

    let capteurCount = 0;
    for (const parcelleId of parcelles) {
      const stationId = uuidv4();

      await db.query(`
        INSERT IGNORE INTO stations (id, parcelle_id, nom, code, modele, statut)
        VALUES (?, ?, ?, ?, 'Modele Alpha', 'ACTIVE')
      `, [stationId, parcelleId, 'Station IoT Alpha', `ST-${stationId.substring(0, 8)}`]);

      // Ajouter des capteurs à chaque station - 6 types spécifiques
      // Ajouter des capteurs à chaque station
      const capteurTypes = [
        'HUMIDITE_SOL',
        'HUMIDITE_TEMPERATURE_AMBIANTE',
        'NPK',
        'UV',
        'DIRECTION_VENT',
        'TRANSPIRATION_PLANTE'
      ];

      for (const type of capteurTypes) {
        let unite = 'unit';
        let nom = 'Capteur Generic';
        switch (type) {
          case 'HUMIDITE_SOL': unite = '%'; nom = 'Sonde Humidité Sol'; break;
          case 'HUMIDITE_TEMPERATURE_AMBIANTE': unite = '°C/%'; nom = 'Capteur Ambiant'; break;
          case 'NPK': unite = 'mg/kg'; nom = 'Sonde NPK'; break;
          case 'UV': unite = 'index'; nom = 'Capteur UV'; break;
          case 'DIRECTION_VENT': unite = 'deg'; nom = 'Anémomètre'; break;
          case 'TRANSPIRATION_PLANTE': unite = 'mmol'; nom = 'Capteur Flux'; break;
        }

        await db.query(`
          INSERT IGNORE INTO capteurs (id, station_id, parcelle_id, nom, type, unite, seuil_min, seuil_max, statut)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'ACTIF')
        `, [
          uuidv4(),
          stationId,
          parcelleId,
          nom,
          type,
          unite,
          // Seuils basiques
          type === 'NPK' ? 5 : 20,
          type === 'NPK' ? 8 : 80
        ]);
        capteurCount++;
      }
    }
    console.log(`   ✅ ${parcelles.length} stations et ${capteurCount} capteurs créés`);

    // Ajouter des mesures de démonstration
    console.log('\n📊 Création des mesures...');

    const capteurs = await db.query(`SELECT id, type FROM capteurs`);
    let mesureCount = 0;

    for (const capteur of capteurs.rows) {
      // Générer des mesures sur les 7 derniers jours
      for (let day = 0; day < 7; day++) {
        for (let hour = 0; hour < 24; hour += 4) {
          const timestamp = new Date();
          timestamp.setDate(timestamp.getDate() - day);
          timestamp.setHours(hour, 0, 0, 0);

          let valeur;
          let unite;

          switch (capteur.type) {
            case 'HUMIDITE_SOL':
              valeur = 40 + Math.random() * 50;
              unite = '%';
              break;

            case 'HUMIDITE_TEMPERATURE_AMBIANTE':
              // Génère soit la température soit l'humidité
              if (Math.random() > 0.5) {
                valeur = 20 + Math.random() * 15;
                unite = '°C';
              } else {
                valeur = 40 + Math.random() * 50;
                unite = '%';
              }
              break;

            case 'NPK':
              valeur = 50 + Math.random() * 100;
              unite = 'mg/kg';
              break;

            case 'UV':
              valeur = Math.floor(Math.random() * 12);
              unite = 'index';
              break;

            case 'DIRECTION_VENT':
              valeur = Math.floor(Math.random() * 360);
              unite = 'deg';
              break;

            case 'TRANSPIRATION_PLANTE':
              valeur = Math.random() * 5;
              unite = 'mmol/m²/s';
              break;

            default:
              valeur = Math.random() * 100;
              unite = 'unit';
          }

          await db.query(`
            INSERT INTO mesures (id, capteur_id, valeur, unite, timestamp)
            VALUES (?, ?, ?, ?, ?)
          `, [uuidv4(), capteur.id, typeof valeur === 'number' ? valeur.toFixed(2) : valeur, unite, timestamp]);
          mesureCount++;
        }
      }
    }
    console.log(`   ✅ ${mesureCount} mesures créées`);

    // Créer des cultures
    console.log('\n🌿 Création des cultures...');

    const cultures = [
      { nom: 'Cacao', categorie: 'fruits', cycle_jours: 1825, temp_ideale_min: 21, temp_ideale_max: 32, humidite_ideale_min: 70, humidite_ideale_max: 90 },
      { nom: 'Café Robusta', categorie: 'fruits', cycle_jours: 1095, temp_ideale_min: 20, temp_ideale_max: 30, humidite_ideale_min: 60, humidite_ideale_max: 85 },
      { nom: 'Hévéa', categorie: 'autres', cycle_jours: 2555, temp_ideale_min: 20, temp_ideale_max: 35, humidite_ideale_min: 75, humidite_ideale_max: 100 },
      { nom: 'Manioc', categorie: 'tubercules', cycle_jours: 365, temp_ideale_min: 25, temp_ideale_max: 35, humidite_ideale_min: 50, humidite_ideale_max: 80 },
      { nom: 'Igname', categorie: 'tubercules', cycle_jours: 270, temp_ideale_min: 25, temp_ideale_max: 30, humidite_ideale_min: 60, humidite_ideale_max: 75 },
      { nom: 'Maïs', categorie: 'cereales', cycle_jours: 120, temp_ideale_min: 18, temp_ideale_max: 32, humidite_ideale_min: 50, humidite_ideale_max: 70 }
    ];

    for (const culture of cultures) {
      await db.query(`
        INSERT IGNORE INTO cultures (id, nom, categorie, duree_jours, temperature_min, temperature_max)
        VALUES (?, ?, ?, ?, ?, ?)
      `, [uuidv4(), culture.nom, culture.categorie === 'autres' ? 'TUBERCULES' : culture.categorie.toUpperCase(), culture.cycle_jours,
      culture.temp_ideale_min, culture.temp_ideale_max]);
    }
    console.log(`   ✅ ${cultures.length} cultures créées`);

    // Créer des maladies
    console.log('\n🦠 Création des maladies...');

    const maladies = [
      { nom: 'Pourriture brune', type: 'fongique', cultures_affectees: ['Cacao'], symptomes: ['taches brunes', 'fruits pourris', 'moisissure blanche'] },
      { nom: 'Swollen Shoot', type: 'virale', cultures_affectees: ['Cacao'], symptomes: ['gonflement tiges', 'feuilles déformées', 'baisse rendement'] },
      { nom: 'Rouille orangée', type: 'fongique', cultures_affectees: ['Café'], symptomes: ['pustules oranges', 'chute feuilles', 'jaunissement'] },
      { nom: 'Anthracnose', type: 'fongique', cultures_affectees: ['Manioc', 'Igname'], symptomes: ['taches noires', 'nécroses', 'dépérissement'] },
      { nom: 'Mosaïque du manioc', type: 'virale', cultures_affectees: ['Manioc'], symptomes: ['marbrure feuilles', 'déformation', 'nanisme'] }
    ];

    for (const maladie of maladies) {
      const desc = maladie.description || `Maladie ${maladie.type} affectant ${maladie.cultures_affectees ? maladie.cultures_affectees.join(', ') : 'les cultures'}`;
      const sympt = Array.isArray(maladie.symptomes) ? maladie.symptomes.join(', ') : (maladie.symptomes || 'Symptômes non décrits');
      const prev = maladie.traitement_preventif || 'Surveillance accrue';
      const cur = maladie.traitement_curatif || 'Intervention agronomique';

      await db.query(`
        INSERT IGNORE INTO maladies (id, nom, description, symptomes, prevention, traitements)
        VALUES (?, ?, ?, ?, ?, ?)
      `, [uuidv4(), maladie.nom, desc, sympt,
      JSON.stringify([prev]), JSON.stringify([cur])]);
    }
    console.log(`   ✅ ${maladies.length} maladies créées`);

    // Créer des diagnostics de test
    console.log('\n🩺 Création des diagnostics de test...');

    const severities = ['low', 'medium', 'high', 'critical'];
    const mockDiagnostics = [];

    for (let i = 0; i < 15; i++) {
      const producteurId = producteurs.rows[i % producteurs.rows.length].id;
      // Find a parcelle for this producer (simple approximations)
      const parcelleId = null; // Can be left null or queried properly if needed, but for history view it's often optional or just needs user_id

      await db.query(`
            INSERT INTO diagnostics (
                id, user_id, parcelle_id, disease_name, crop_type, 
                confidence_score, severity, image_url, 
                recommendations, treatment_suggestions, created_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `, [
        uuidv4(),
        producteurId,
        parcelleId,
        ['Mildiou', 'Mosaïque', 'Rouille', 'Chenille'][i % 4],
        ['Tomate', 'Manioc', 'Maïs', 'Cacao'][i % 4],
        (70 + Math.random() * 29).toFixed(2),
        severities[i % severities.length],
        'https://placeholder.com/plant.jpg',
        'Surveiller l\'évolution des symptômes. Isoler les plants touchés.',
        'Application de fongicide bio recommandée si l\'infestation dépasse 10%.',
        new Date(Date.now() - Math.floor(Math.random() * 14 * 24 * 60 * 60 * 1000)) // Random date in last 14 days
      ]);
      mockDiagnostics.push(i);
    }
    console.log(`   ✅ ${mockDiagnostics.length} diagnostics créés`);

    // Créer des formations
    console.log('\n📚 Création des formations...');

    const conseillerId = (await db.query(`SELECT id FROM users WHERE role = 'conseiller' LIMIT 1`)).rows[0]?.id;

    const formations = [
      { titre: 'Introduction à l\'agriculture intelligente', description: 'Découvrez les bases de l\'agriculture moderne et connectée.', url: 'https://example.com/intro-agri-smart', type: 'video', niveau: 'debutant', duree: 60, categorie: 'culture' },
      { titre: 'Gestion de l\'irrigation', description: 'Apprenez les techniques d\'irrigation efficaces pour optimiser vos rendements.', url: 'https://example.com/irrigation-gestion', type: 'tutoriel', niveau: 'intermediaire', duree: 45, categorie: 'pratique' },
      { titre: 'Détection des maladies du cacao', description: 'Identifiez et prévenez les maladies courantes du cacaoyer.', url: 'https://example.com/maladies-cacao', type: 'tutoriel', niveau: 'avance', duree: 90, categorie: 'maladie' },
      { titre: 'Utilisation des capteurs IoT', description: 'Maîtrisez l\'installation et l\'analyse des données des capteurs IoT.', url: 'https://example.com/capteurs-iot', type: 'pratique', niveau: 'intermediaire', duree: 120, categorie: 'technologie' }
    ];

    for (const formation of formations) {
      await db.query(`
        INSERT IGNORE INTO formations (id, titre, description, duree_minutes, categorie)
        VALUES (?, ?, ?, ?, ?)
      `, [uuidv4(), formation.titre, formation.description,
      formation.duree, formation.categorie]);
    }
    console.log(`   ✅ ${formations.length} formations créées`);

    // Créer des produits marketplace
    console.log('\n🛒 Création des produits marketplace...');

    const produits = [
      { nom: 'Cacao séché premium', categorie: 'recolte', prix: 1500, unite: 'kg', quantite: 500 },
      { nom: 'Café torréfié artisanal', categorie: 'recolte', prix: 3000, unite: 'kg', quantite: 100 },
      { nom: 'Semences de maïs hybride', categorie: 'semences', prix: 5000, unite: 'sac', quantite: 50 },
      { nom: 'Engrais NPK 15-15-15', categorie: 'intrants', prix: 25000, unite: 'sac', quantite: 30 }
    ];

    // Récupérer une région pour les produits
    const regionId = (await db.query(`SELECT id FROM regions LIMIT 1`)).rows[0]?.id;

    for (let i = 0; i < produits.length; i++) {
      const produit = produits[i];
      const vendeurId = producteurs.rows[i % producteurs.rows.length].id;

      await db.query(`
        INSERT INTO marketplace_produits (id, vendeur_id, nom, description, categorie, prix, unite, stock, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
      `, [uuidv4(), vendeurId, produit.nom, `${produit.nom} de qualité supérieure`,
      produit.categorie, produit.prix, produit.unite, produit.quantite]);
    }
    console.log(`   ✅ ${produits.length} produits créés`);

    /*
    // Créer des posts forum - SKIPPED DUE TO SCHEMA ERROR
    console.log('\n💬 Création des posts forum SKIPPED...');
    */

    console.log('\n✨ Seed terminé avec succès!\n');
    console.log('📋 Utilisateurs de test:');
    console.log('   Admin:      +2250101010101 / password123');
    console.log('   Conseiller: +2250102020202 / password123');
    console.log('   Producteur: +2250103030303 / password123');
    console.log('');

  } catch (error) {
    console.error('❌ Erreur lors du seed:', error);
    throw error;
  } finally {
    await db.closePool();
  }
}

// Exécuter si appelé directement
if (require.main === module) {
  seed().catch(console.error);
}

module.exports = seed;
