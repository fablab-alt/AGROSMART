const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });

function randomInt(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
function randomElement(arr) { return arr[Math.floor(Math.random() * arr.length)]; }
function daysAgo(d) { const dt = new Date(); dt.setDate(dt.getDate() - d); return dt; }

async function main() {
  const users = await p.user.findMany({ where: { role: 'PRODUCTEUR' }, select: { id: true } });
  const formations = await p.formation.findMany({ select: { id: true } });
  
  console.log('Creating progressions for', users.length, 'producteurs across', formations.length, 'formations...');
  
  let count = 0;
  for (const user of users) {
    const numEnroll = randomInt(1, Math.min(3, formations.length));
    const enrolled = [];
    for (let i = 0; i < numEnroll; i++) {
      let f;
      do { f = randomElement(formations); } while (enrolled.includes(f.id));
      enrolled.push(f.id);
      
      const modules = await p.moduleFormation.findMany({
        where: { formationId: f.id },
        orderBy: { ordre: 'asc' },
        select: { id: true }
      });
      const numDone = randomInt(0, modules.length);
      const pct = modules.length > 0 ? Math.round((numDone / modules.length) * 100) : 0;
      const completedIds = modules.slice(0, numDone).map(m => m.id);
      
      try {
        await p.progressionFormation.create({
          data: {
            userId: user.id,
            formationId: f.id,
            progression: pct,
            complete: pct >= 100,
            modulesTermines: completedIds,
            score: pct >= 100 ? randomInt(70, 100) : null,
            dateDebut: daysAgo(randomInt(10, 90)),
            dateFin: pct >= 100 ? daysAgo(randomInt(0, 10)) : null,
          }
        });
        count++;
      } catch(e) { /* skip unique constraint violations */ }
    }
  }
  
  console.log('Created', count, 'progressions');
  await p.$disconnect();
}

main();
