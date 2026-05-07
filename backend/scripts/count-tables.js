const{PrismaClient}=require('@prisma/client');
const p=new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });
(async()=>{
  const tables=['user','parcelle','capteur','mesure','alerte','stock','mouvementStock','recommandation','formation','moduleFormation','progressionFormation','forumPost','forumReponse','plantation','recolte','roiTracking','economies','performanceParcelle','rendementParCulture'];
  for(const t of tables){
    const c=await p[t].count();
    console.log(t.padEnd(25)+': '+c);
  }
  await p.$disconnect();
})();
