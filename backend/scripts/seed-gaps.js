const{PrismaClient}=require('@prisma/client');
const p=new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });

function randomBetween(min, max) { return Math.round((Math.random() * (max - min) + min) * 100) / 100; }
function randomInt(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
function randomElement(arr) { return arr[Math.floor(Math.random() * arr.length)]; }
function daysAgo(d) { const dt = new Date(); dt.setDate(dt.getDate() - d); return dt; }

async function main() {
  // Seed mouvements for existing stocks
  const stocks = await p.stock.findMany({ select: { id: true, quantite: true, categorie: true } });
  console.log('Creating mouvements for', stocks.length, 'stocks...');
  let mvtCount = 0;
  for (const stock of stocks) {
    const numMvts = randomInt(2, 5);
    let currentQte = 0;
    for (let j = 0; j < numMvts; j++) {
      const typeMouvement = j === 0 ? 'ENTREE' : randomElement(['ENTREE', 'ENTREE', 'SORTIE', 'SORTIE', 'AJUSTEMENT']);
      const qteAvant = currentQte;
      const qteMouvement = randomBetween(5, Math.max(10, Number(stock.quantite) * 0.3));
      
      if (typeMouvement === 'SORTIE' && currentQte < qteMouvement) {
        currentQte += qteMouvement;
        await p.mouvementStock.create({
          data: {
            stockId: stock.id, typeMouvement: 'ENTREE', quantite: qteMouvement,
            quantiteAvant: qteAvant, quantiteApres: currentQte,
            motif: randomElement(['Approvisionnement', 'Réception commande', 'Don coopérative']),
            createdAt: daysAgo(randomInt(1, 90)),
          }
        });
      } else {
        currentQte = typeMouvement === 'SORTIE' ? currentQte - qteMouvement : currentQte + qteMouvement;
        await p.mouvementStock.create({
          data: {
            stockId: stock.id, typeMouvement, quantite: qteMouvement,
            quantiteAvant: qteAvant, quantiteApres: Math.max(0, currentQte),
            motif: typeMouvement === 'ENTREE'
              ? randomElement(['Approvisionnement', 'Réception commande', 'Don coopérative'])
              : typeMouvement === 'SORTIE'
              ? randomElement(['Application parcelle', 'Utilisation terrain', 'Vente partielle'])
              : 'Inventaire correctif',
            createdAt: daysAgo(randomInt(1, 60)),
          }
        });
      }
      mvtCount++;
    }
  }
  console.log('Created', mvtCount, 'mouvements stock');

  // Seed rendement par culture
  const parcelles = await p.parcelle.findMany({ select: { id: true } });
  const cultures = await p.culture.findMany({ select: { id: true } });
  const currentYear = new Date().getFullYear();
  let rendCount = 0;
  
  if (cultures.length > 0) {
    for (const parcelle of parcelles) {
      for (let y = 0; y < 2; y++) {
        const cultureId = randomElement(cultures).id;
        try {
          await p.rendementParCulture.create({
            data: {
              parcelleId: parcelle.id, cultureId, annee: currentYear - y,
              rendementKgHa: randomBetween(300, 1500),
              qualite: randomElement(['Excellente', 'Bonne', 'Moyenne']),
              notes: randomElement(['Saison favorable', 'Impact sécheresse modéré', 'Bon résultat avec irrigation', null]),
            }
          });
          rendCount++;
        } catch(e) { /* skip unique constraint */ }
      }
    }
  }
  console.log('Created', rendCount, 'rendements par culture');
  await p.$disconnect();
}

main();
