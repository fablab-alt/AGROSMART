/**
 * Seed Economies data for analytics
 * Run: docker exec agrismart_api node scripts/seed_economies.js
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });

async function main() {
  console.log('🌱 Seeding Economies data...');

  // Get all users who have parcelles (PRODUCTEUR)
  const users = await prisma.user.findMany({
    where: { role: 'PRODUCTEUR' },
    select: { id: true, nom: true }
  });

  if (users.length === 0) {
    console.log('❌ No PRODUCTEUR users found.');
    return;
  }

  console.log(`👤 Found ${users.length} producteur users`);

  const periods = [
    { debut: '2024-01-01', fin: '2024-03-31' },
    { debut: '2024-04-01', fin: '2024-06-30' },
    { debut: '2024-07-01', fin: '2024-09-30' },
    { debut: '2024-10-01', fin: '2024-12-31' },
    { debut: '2025-01-01', fin: '2025-03-31' },
    { debut: '2025-04-01', fin: '2025-06-30' },
  ];

  let created = 0;
  for (const user of users) {
    for (const period of periods) {
      // Realistic water savings: 10-35%
      const eauPct = 10 + Math.random() * 25;
      // Fertilizer savings: 5-25%
      const engraisPct = 5 + Math.random() * 20;
      // Disease loss prevention: 15-45%
      const pertesPct = 15 + Math.random() * 30;

      // Values in FCFA
      const valEau = 50000 + Math.random() * 200000;
      const valEngrais = 30000 + Math.random() * 150000;
      const valPertes = 100000 + Math.random() * 500000;
      const total = valEau + valEngrais + valPertes;

      try {
        await prisma.economies.create({
          data: {
            userId: user.id,
            eauEconomiseePourcentage: parseFloat(eauPct.toFixed(2)),
            engraisEconomisePourcentage: parseFloat(engraisPct.toFixed(2)),
            pertesEviteesPourcentage: parseFloat(pertesPct.toFixed(2)),
            valeurEauEconomiseeFcfa: parseFloat(valEau.toFixed(2)),
            valeurEngraisEconomiseFcfa: parseFloat(valEngrais.toFixed(2)),
            valeurPertesEviteesFcfa: parseFloat(valPertes.toFixed(2)),
            economiesTotalesFcfa: parseFloat(total.toFixed(2)),
            dateDebut: new Date(period.debut),
            dateFin: new Date(period.fin),
          }
        });
        created++;
      } catch (e) {
        console.error(`Error for user ${user.nom}:`, e.message);
      }
    }
  }

  console.log(`✅ ${created} economies records created`);

  const count = await prisma.economies.count();
  console.log(`📊 Total economies records: ${count}`);
}

main()
  .catch((e) => {
    console.error('❌ Error:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
