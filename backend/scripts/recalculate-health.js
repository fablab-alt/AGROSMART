/**
 * Script pour recalculer la santé de toutes les parcelles
 * basé sur les dernières mesures des capteurs
 * 
 * Usage: node scripts/recalculate-health.js
 */

const prisma = require('../src/config/prisma');
const parcelleHealthService = require('../src/services/parcelleHealthService');

async function main() {
  console.log('🔄 Recalcul de la santé de toutes les parcelles...\n');

  const parcelles = await prisma.parcelle.findMany({
    select: { id: true, nom: true, sante: true }
  });

  console.log(`📊 ${parcelles.length} parcelles trouvées\n`);

  let updated = 0;
  let changed = 0;

  for (const p of parcelles) {
    const oldHealth = p.sante;
    const newHealth = await parcelleHealthService.recalculateParcelleHealth(p.id);
    
    const marker = newHealth !== oldHealth ? '⚡' : '✅';
    console.log(`${marker} ${p.nom}: ${oldHealth} → ${newHealth}`);
    
    updated++;
    if (newHealth !== oldHealth) changed++;
  }

  console.log(`\n✅ ${updated} parcelles recalculées, ${changed} changées`);
  await prisma.$disconnect();
}

main().catch(e => {
  console.error('❌ Erreur:', e);
  prisma.$disconnect();
  process.exit(1);
});
