/**
 * Script de Seed Complémentaire - Tables Manquantes
 * Remplit uniquement les tables qui sont encore vides
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });

const FORMATIONS_DATA = [
  {
    titre: 'Introduction à l\'agriculture intelligente',
    description: 'Découvrez les bases de l\'agriculture de précision et les technologies IoT',
    categorie: 'technologie',
    niveau: 'Débutant',
    dureeMinutes: 90,
    modules: [
      { titre: 'Qu\'est-ce que l\'agriculture intelligente ?', contenu: 'Introduction aux concepts de base', ordre: 1 },
      { titre: 'Les capteurs IoT en agriculture', contenu: 'Types de capteurs et leurs utilisations', ordre: 2 },
      {titre: 'Interprétation des données', contenu: 'Comment lire et utiliser les données collectées', ordre: 3 }
    ]
  },
  {
    titre: 'Culture du cacao : de la plantation à la récolte',
    description: 'Formation complète sur les techniques modernes de cacaoculture',
    categorie: 'culture',
    niveau: 'Intermédiaire',
    dureeMinutes: 180,
    modules: [
      { titre: 'Préparation du terrain', contenu: 'Choix du site et préparation du sol', ordre: 1 },
      { titre: 'Plantation et entretien', contenu: 'Techniques de plantation et soins jeunes plants', ordre: 2 },
      { titre: 'Récolte et post-récolte', contenu: 'Cueillette, fermentation et séchage', ordre: 3 }
    ]
  },
  {
    titre: 'Gestion de l\'irrigation',
    description: 'Optimisez votre consommation d\'eau avec les techniques modernes',
    categorie: 'pratique',
    niveau: 'Intermédiaire',
    dureeMinutes: 120,
    modules: [
      { titre: 'Besoins en eau des cultures', contenu: 'Calcul des besoins hydriques', ordre: 1 },
      { titre: 'Systèmes d\'irrigation', contenu: 'Goutte-à-goutte, aspersion, gravitaire', ordre: 2 }
    ]
  }
];

const BADGES_DATA = [
  { nom: 'Pionnier', description: 'Première connexion à l\'application', icone: '🌱', points: 10, condition: { type: 'login', count: 1 } },
  { nom: 'Connecté', description: 'Se connecter 7 jours consécutifs', icone: '🔥', points: 50, condition: { type: 'consecutive_days', count: 7 } },
  { nom: 'Gestionnaire', description: 'Créer 5 parcelles', icone: '🗺️', points: 30, condition: { type: 'parcelle_count', count: 5 } },
  { nom: 'Technicien IoT', description: 'Installer 10 capteurs', icone: '📡', points: 40, condition: { type: 'capteur_count', count: 10 } },
  { nom: 'Étudiant assidu', description: 'Compléter 3 formations', icone: '🎓', points: 60, condition: { type: 'formation_completed', count: 3 } }
];

const REALISATIONS_DATA = [
  { nom: 'Première récolte', description: 'Enregistrer votre première récolte', points: 20, objectif: { type: 'recolte', count: 1 } },
  { nom: 'Récolte abondante', description: 'Récolter plus de 1000 kg au total', points: 50, objectif: { type: 'recolte_total_kg', threshold: 1000 } },
  { nom: 'Explorateur de données', description: 'Consulter vos statistiques 10 fois', points: 15, objectif: { type: 'stats_view', count: 10 } }
];

async function main() {
  console.log('🔧 Complément du seed - Tables manquantes\n');
  
  try {
    // Formations
    console.log('📚 Création des formations...');
    for (const formationData of FORMATIONS_DATA) {
      const formation = await prisma.formation.create({
        data: {
          titre: formationData.titre,
          description: formationData.description,
          categorie: formationData.categorie,
          niveau: formationData.niveau,
          dureeMinutes: formationData.dureeMinutes,
          imageUrl: `https://storage.agrosmart.ci/formations/default.jpg`,
          vues: Math.floor(Math.random() * 100)
        }
      });
      
      for (const moduleData of formationData.modules) {
        await prisma.moduleFormation.create({
          data: {
            formationId: formation.id,
            titre: moduleData.titre,
            contenu: moduleData.contenu,
            ordre: moduleData.ordre
          }
        });
      }
    }
    console.log(`  ✅ ${FORMATIONS_DATA.length} formations créées\n`);
    
    // Badges
    console.log('🏆 Création des badges...');
    for (const badgeData of BADGES_DATA) {
      await prisma.badge.create({ data: badgeData });
    }
    console.log(`  ✅ ${BADGES_DATA.length} badges créés\n`);
    
    // Réalisations
    console.log('🎯 Création des réalisations...');
    for (const realisationData of REALISATIONS_DATA) {
      await prisma.realisation.create({ data: realisationData });
    }
    console.log(`  ✅ ${REALISATIONS_DATA.length} réalisations créées\n`);
    
    // Forum Posts
    console.log('💬 Création des posts forum...');
    const users = await prisma.user.findMany({ take: 10 });const categories = ['culture', 'maladies', 'equipement'];
    const titres = [
      'Meilleur moment pour planter le cacao ?',
      'Problème de jaunissement des feuilles',
      'Recommandation système d\'irrigation'
    ];
    
    for (let i = 0; i < 15; i++) {
      const auteur = users[Math.floor(Math.random() * users.length)];
      const post = await prisma.forumPost.create({
        data: {
          auteurId: auteur.id,
          titre: titres[i % titres.length],
          contenu: 'Bonjour, j\'aimerais avoir vos conseils...',
          categorie: categories[i % categories.length],
          vues: Math.floor(Math.random() * 50),
          resolu: Math.random() > 0.5
        }
      });
      
      // 2-3 réponses
      for (let j = 0; j < 2 + Math.floor(Math.random() * 2); j++) {
        const repondant = users[Math.floor(Math.random() * users.length)];
        await prisma.forumReponse.create({
          data: {
            postId: post.id,
            auteurId: repondant.id,
            contenu: 'Voici mon conseil basé sur mon expérience...',
            upvotes: Math.floor(Math.random() * 10)
          }
        });
      }
    }
    console.log(`  ✅ 15 posts forum créés\n`);
    
    // Stocks
    console.log('📦 Création des stocks...');
    const producteurs = await prisma.user.findMany({ where: { role: 'PRODUCTEUR' }, take: 15 });
    const categories_stock = ['SEMENCES', 'ENGRAIS', 'PESTICIDES', 'RECOLTES'];
    let stockCount = 0;
    
    for (const producteur of producteurs) {
      for (let i = 0; i < 3; i++) {
        await prisma.stock.create({
          data: {
            userId: producteur.id,
            nom: `Stock ${categories_stock[i % categories_stock.length]}`,
            categorie: categories_stock[i % categories_stock.length],
            type: 'Type standard',
            quantite: 50 + Math.random() * 200,
            unite: 'kg',
            seuilAlerte: 20,
            prixUnitaire: 1000 + Math.random() * 5000
          }
        });
        stockCount++;
      }
    }
    console.log(`  ✅ ${stockCount} stocks créés\n`);
    
    // Calendrier
    console.log('📅 Création des activités calendrier...');
    const typesActivites = ['SEMIS', 'PLANTATION', 'ARROSAGE', 'FERTILISATION', 'RECOLTE'];
    let activiteCount = 0;
    
    for (const producteur of producteurs) {
      for (let i = 0; i < 5; i++) {
        const dateDebut = new Date(Date.now() + (Math.random() - 0.5) * 30 * 24 * 60 * 60 * 1000);
        await prisma.calendrierActivite.create({
          data: {
            userId: producteur.id,
            titre: `${typesActivites[i % typesActivites.length]} - Cacao`,
            typeActivite: typesActivites[i % typesActivites.length],
            statut: dateDebut < new Date() ? 'TERMINEE' : 'PLANIFIEE',
            priorite: 'MOYENNE',
            dateDebut: dateDebut
          }
        });
        activiteCount++;
      }
    }
    console.log(`  ✅ ${activiteCount} activités créées\n`);
    
    console.log('✨ Complément terminé avec succès !\n');
    
  } catch (error) {
    console.error('❌ Erreur:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

main().catch(console.error);
