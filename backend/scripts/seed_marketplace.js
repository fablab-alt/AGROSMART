/**
 * Seed Marketplace Products (safe)
 * Agrosmart CI
 */

const prisma = require('../src/config/prisma');

const sampleProducts = [
  {
    nom: 'Mangues Kent',
    description: 'Mangues fraîches de saison',
    categorie: 'fruit',
    prix: 800,
    unite: 'kg',
    stock: 120
  },
  {
    nom: 'Tomates fraîches',
    description: 'Tomates bio récoltées du jour',
    categorie: 'legume',
    prix: 600,
    unite: 'kg',
    stock: 200
  },
  {
    nom: 'Riz local',
    description: 'Riz local de qualité supérieure',
    categorie: 'cereale',
    prix: 900,
    unite: 'kg',
    stock: 500
  },
  {
    nom: 'Igname',
    description: 'Igname fraîchement récoltée',
    categorie: 'tubercule',
    prix: 700,
    unite: 'kg',
    stock: 150
  },
  {
    nom: 'Piment',
    description: 'Piment fort',
    categorie: 'legume',
    prix: 1200,
    unite: 'kg',
    stock: 80
  },
  {
    nom: 'Banane plantain',
    description: 'Plantain mûr',
    categorie: 'fruit',
    prix: 500,
    unite: 'kg',
    stock: 180
  }
];

async function seedMarketplace() {
  try {
    await prisma.$connect();

    const producteurs = await prisma.user.findMany({
      where: { role: 'PRODUCTEUR', isActive: true },
      select: { id: true }
    });

    if (producteurs.length === 0) {
      console.log('⚠️ Aucun producteur trouvé.');
      return;
    }

    let created = 0;
    for (let i = 0; i < sampleProducts.length; i++) {
      const vendeur = producteurs[i % producteurs.length];
      const existing = await prisma.marketplaceProduit.count({
        where: {
          vendeurId: vendeur.id,
          nom: sampleProducts[i].nom
        }
      });

      if (existing > 0) continue;

      await prisma.marketplaceProduit.create({
        data: {
          vendeurId: vendeur.id,
          nom: sampleProducts[i].nom,
          description: sampleProducts[i].description,
          categorie: sampleProducts[i].categorie,
          prix: sampleProducts[i].prix,
          unite: sampleProducts[i].unite,
          stock: sampleProducts[i].stock,
          images: [],
          typeOffre: 'vente',
          actif: true
        }
      });
      created++;
    }

    console.log(`✅ ${created} produits marketplace ajoutés.`);
  } catch (error) {
    console.error('❌ Erreur seed marketplace:', error);
    process.exitCode = 1;
  } finally {
    await prisma.$disconnect();
  }
}

seedMarketplace();
