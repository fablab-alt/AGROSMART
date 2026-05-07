/**
 * Script de création d'un compte administrateur
 * AgroSmart - Système Agricole Intelligent
 * 
 * Usage: node scripts/seed_admin.js
 */

const bcrypt = require('bcryptjs');
const path = require('path');
const crypto = require('crypto');

// Load env
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const prisma = require('../src/config/prisma');

async function createAdmin() {
  console.log('🔐 Création du compte administrateur AgroSmart...\n');

  const generatedPassword = crypto.randomBytes(12).toString('base64url') + '9!aA';

  // ⚠️ SÉCURITÉ: Le mot de passe par défaut est utilisé UNIQUEMENT en développement
  // En production, définir ADMIN_PASSWORD dans .env
  const adminData = {
    telephone: process.env.ADMIN_TELEPHONE || '+2250100000000',
    email: process.env.ADMIN_EMAIL || 'admin@agrosmart.ci',
    password: process.env.ADMIN_PASSWORD || generatedPassword,
    nom: 'Administrateur',
    prenoms: 'AgroSmart',
    role: 'ADMIN',
  };

  if (!process.env.ADMIN_PASSWORD) {
    console.warn('⚠️  ADMIN_PASSWORD absent: mot de passe temporaire généré automatiquement.');
    console.warn('   Définissez ADMIN_PASSWORD dans .env pour un mot de passe déterministe.');
  }

  try {
    // Vérifier si un admin existe déjà
    const existingAdmin = await prisma.user.findFirst({
      where: {
        OR: [
          { email: adminData.email },
          { telephone: adminData.telephone },
          { role: 'ADMIN' }
        ]
      }
    });

    if (existingAdmin) {
      console.log('⚠️  Un compte admin existe déjà:');
      console.log(`   Email: ${existingAdmin.email}`);
      console.log(`   Téléphone: ${existingAdmin.telephone}`);
      console.log(`   Nom: ${existingAdmin.prenoms} ${existingAdmin.nom}`);
      console.log(`   Rôle: ${existingAdmin.role}`);
      console.log(`   Statut: ${existingAdmin.status}`);
      
      // S'assurer que le compte est actif
      if (existingAdmin.status !== 'ACTIF') {
        await prisma.user.update({
          where: { id: existingAdmin.id },
          data: { status: 'ACTIF' }
        });
        console.log('   ✅ Statut mis à jour vers ACTIF');
      }

      // Mettre à jour le mot de passe pour être sûr
      const hashedPassword = await bcrypt.hash(adminData.password, 12);
      await prisma.user.update({
        where: { id: existingAdmin.id },
        data: { passwordHash: hashedPassword }
      });
      console.log('   ✅ Mot de passe réinitialisé');
      
      console.log('\n📋 Identifiants de connexion:');
      console.log(`   Téléphone: ${existingAdmin.telephone}`);
      console.log(`   Email: ${existingAdmin.email}`);
      console.log(`   Mot de passe: ${adminData.password}`);
      return;
    }

    // Hasher le mot de passe
    const hashedPassword = await bcrypt.hash(adminData.password, 12);

    // Créer l'administrateur
    const admin = await prisma.user.create({
      data: {
        telephone: adminData.telephone,
        email: adminData.email,
        passwordHash: hashedPassword,
        nom: adminData.nom,
        prenoms: adminData.prenoms,
        role: adminData.role,
        status: 'ACTIF',
        emailVerifie: true,
      },
      select: {
        id: true,
        email: true,
        telephone: true,
        nom: true,
        prenoms: true,
        role: true,
        status: true,
      }
    });

    console.log('✅ Compte administrateur créé avec succès!\n');
    console.log('📋 Détails du compte:');
    console.log(`   ID: ${admin.id}`);
    console.log(`   Nom: ${admin.prenoms} ${admin.nom}`);
    console.log(`   Email: ${admin.email}`);
    console.log(`   Téléphone: ${admin.telephone}`);
    console.log(`   Rôle: ${admin.role}`);
    console.log(`   Statut: ${admin.status}`);
    console.log(`\n🔑 Identifiants de connexion:`);
    console.log(`   Téléphone: ${adminData.telephone}`);
    console.log(`   Email: ${adminData.email}`);
    console.log(`   Mot de passe: ${adminData.password}`);

  } catch (error) {
    console.error('❌ Erreur lors de la création du compte admin:', error.message);
    if (error.code === 'P2002') {
      console.error('   Un utilisateur avec cet email ou ce téléphone existe déjà.');
    }
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

createAdmin()
  .then(() => {
    console.log('\n🎉 Script terminé avec succès!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Erreur fatale:', error);
    process.exit(1);
  });
