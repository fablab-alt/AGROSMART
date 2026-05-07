/**
 * Seed Performance Parcelles & ROI Tracking data
 * Run: docker exec agrismart_api node scripts/seed_performance_roi.js
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });

async function main() {
  console.log('🌱 Seeding Performance & ROI data...');

  // Get all parcelles with their users
  const parcelles = await prisma.parcelle.findMany({
    include: { user: { select: { id: true, nom: true } } }
  });

  if (parcelles.length === 0) {
    console.log('❌ No parcelles found. Run seed.js first.');
    return;
  }

  console.log(`📊 Found ${parcelles.length} parcelles`);

  // ==================== PERFORMANCE PARCELLES ====================
  const perfData = [];
  const years = [2023, 2024, 2025];
  const pratiques = [
    'Rotation des cultures avec légumineuses',
    'Utilisation de compost organique',
    'Irrigation goutte-à-goutte',
    'Couverture du sol avec paillage',
    'Agroforesterie avec ombrage optimisé',
    'Fertilisation raisonnée basée sur analyses',
    'Lutte biologique intégrée',
    'Semis direct sous couvert végétal',
  ];

  for (const parcelle of parcelles) {
    for (const annee of years) {
      // Generate realistic data with progressive improvement
      const yearMultiplier = 1 + (annee - 2023) * 0.08; // 8% improvement per year
      const baseRendement = 1.5 + Math.random() * 3.5; // 1.5-5.0 t/ha
      const baseQualite = 45 + Math.random() * 40; // 45-85 score

      perfData.push({
        userId: parcelle.userId,
        parcelleId: parcelle.id,
        annee,
        rendementMoyen: parseFloat((baseRendement * yearMultiplier).toFixed(2)),
        scoreQualiteSol: parseFloat(Math.min(100, baseQualite * yearMultiplier).toFixed(2)),
        meilleurePratique: pratiques[Math.floor(Math.random() * pratiques.length)],
      });
    }
  }

  // Upsert to avoid duplicates
  let perfCreated = 0;
  for (const data of perfData) {
    try {
      await prisma.performanceParcelle.upsert({
        where: {
          parcelleId_annee: {
            parcelleId: data.parcelleId,
            annee: data.annee,
          }
        },
        update: data,
        create: data,
      });
      perfCreated++;
    } catch (e) {
      // Skip duplicates
    }
  }
  console.log(`✅ ${perfCreated} performance records created`);

  // ==================== ROI TRACKING ====================
  const roiData = [];
  const periods = [
    { debut: '2023-01-01', fin: '2023-06-30', label: 'S1 2023' },
    { debut: '2023-07-01', fin: '2023-12-31', label: 'S2 2023' },
    { debut: '2024-01-01', fin: '2024-06-30', label: 'S1 2024' },
    { debut: '2024-07-01', fin: '2024-12-31', label: 'S2 2024' },
    { debut: '2025-01-01', fin: '2025-06-30', label: 'S1 2025' },
    { debut: '2025-07-01', fin: '2025-12-31', label: 'S2 2025' },
  ];

  const trends = ['hausse', 'stable', 'baisse'];

  // Get unique user IDs from parcelles
  const userParcelles = {};
  for (const p of parcelles) {
    if (!userParcelles[p.userId]) userParcelles[p.userId] = [];
    userParcelles[p.userId].push(p.id);
  }

  for (const [userId, parcelleIds] of Object.entries(userParcelles)) {
    for (const parcelleId of parcelleIds) {
      for (const period of periods) {
        // Generate realistic costs (in FCFA)
        const coutSemences = 15000 + Math.random() * 85000; // 15k-100k
        const coutEngrais = 25000 + Math.random() * 125000; // 25k-150k
        const coutPesticides = 10000 + Math.random() * 50000; // 10k-60k
        const coutIrrigation = 5000 + Math.random() * 45000; // 5k-50k
        const coutMainOeuvre = 30000 + Math.random() * 120000; // 30k-150k
        const autresCouts = 5000 + Math.random() * 25000; // 5k-30k

        const totalCouts = coutSemences + coutEngrais + coutPesticides + coutIrrigation + coutMainOeuvre + autresCouts;

        // Revenue should be realistic - sometimes profitable, sometimes not
        const quantiteRecoltee = 500 + Math.random() * 4500; // 500-5000 kg
        const prixVenteUnitaire = 150 + Math.random() * 850; // 150-1000 FCFA/kg
        const revenus = quantiteRecoltee * prixVenteUnitaire;

        const roi = revenus > totalCouts ? 'hausse' : revenus < totalCouts * 0.8 ? 'baisse' : 'stable';

        roiData.push({
          userId,
          parcelleId,
          periodeDebut: new Date(period.debut),
          periodeFin: new Date(period.fin),
          coutSemences: parseFloat(coutSemences.toFixed(2)),
          coutEngrais: parseFloat(coutEngrais.toFixed(2)),
          coutPesticides: parseFloat(coutPesticides.toFixed(2)),
          coutIrrigation: parseFloat(coutIrrigation.toFixed(2)),
          coutMainOeuvre: parseFloat(coutMainOeuvre.toFixed(2)),
          autresCouts: parseFloat(autresCouts.toFixed(2)),
          quantiteRecoltee: parseFloat(quantiteRecoltee.toFixed(2)),
          prixVenteUnitaire: parseFloat(prixVenteUnitaire.toFixed(2)),
          roiTrend: roi,
        });
      }
    }
  }

  // Create ROI records
  let roiCreated = 0;
  for (const data of roiData) {
    try {
      await prisma.roiTracking.create({ data });
      roiCreated++;
    } catch (e) {
      // Skip on error
    }
  }
  console.log(`✅ ${roiCreated} ROI tracking records created`);

  // ==================== SUMMARY ====================
  const counts = await Promise.all([
    prisma.performanceParcelle.count(),
    prisma.roiTracking.count(),
  ]);
  console.log(`\n📈 Final counts:`);
  console.log(`   Performance parcelles: ${counts[0]}`);
  console.log(`   ROI tracking: ${counts[1]}`);
  console.log('✅ Seeding completed!');
}

main()
  .catch((e) => {
    console.error('❌ Error:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
