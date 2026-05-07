const axios = require('axios');
const path = require('path');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');

require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const API_BASE = process.env.API_BASE_URL || `http://localhost:${process.env.PORT || 3600}/api/v1`;

function randomDigits(size) {
  const min = 10 ** (size - 1);
  const max = 10 ** size - 1;
  return String(Math.floor(Math.random() * (max - min + 1)) + min);
}

function tokenFor(user) {
  return jwt.sign(
    { userId: user.id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: '30m' },
  );
}

async function run() {
  const prisma = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });
  const results = [];
  const tempIds = [];

  const push = (name, ok, detail) => results.push({ name, ok, detail });

  const assertStatus = async (name, requester, pathUrl, expected) => {
    try {
      const res = await requester.get(pathUrl, {
        validateStatus: () => true,
      });
      const ok = expected.includes(res.status);
      push(name, ok, `status=${res.status}`);
      return ok;
    } catch (error) {
      push(name, false, error.message || 'request error');
      return false;
    }
  };

  try {
    if (!process.env.JWT_SECRET) {
      throw new Error('JWT_SECRET manquant pour la validation plateforme');
    }

    const admin = await prisma.user.findFirst({
      where: { role: 'ADMIN', status: 'ACTIF' },
      select: { id: true, role: true },
    });

    if (!admin) {
      throw new Error('Aucun admin ACTIF trouvé en base');
    }

    const hash = await bcrypt.hash(`Tmp!${randomDigits(6)}Aa`, 10);
    const now = Date.now();

    const rolePayloads = [
      { role: 'PRODUCTEUR', email: `prod.${now}@agrosmart.ci`, phone: `+22507${randomDigits(8)}`, nom: 'Prod', prenoms: 'Tester' },
      { role: 'CONSEILLER', email: `cons.${now}@agrosmart.ci`, phone: `+22501${randomDigits(8)}`, nom: 'Cons', prenoms: 'Tester' },
      { role: 'ACHETEUR', email: `ach.${now}@agrosmart.ci`, phone: `+22508${randomDigits(8)}`, nom: 'Ach', prenoms: 'Tester' },
      { role: 'FOURNISSEUR', email: `four.${now}@agrosmart.ci`, phone: `+22509${randomDigits(8)}`, nom: 'Four', prenoms: 'Tester' },
    ];

    const created = [];
    for (const p of rolePayloads) {
      const u = await prisma.user.create({
        data: {
          email: p.email,
          telephone: p.phone,
          passwordHash: hash,
          nom: p.nom,
          prenoms: p.prenoms,
          role: p.role,
          status: 'ACTIF',
          emailVerifie: true,
        },
        select: { id: true, role: true },
      });
      tempIds.push(u.id);
      created.push(u);
    }

    const adminClient = axios.create({
      baseURL: API_BASE,
      headers: { Authorization: `Bearer ${tokenFor(admin)}` },
      timeout: 20000,
    });

    const byRole = Object.fromEntries(
      created.map((u) => [
        u.role,
        axios.create({
          baseURL: API_BASE,
          headers: { Authorization: `Bearer ${tokenFor(u)}` },
          timeout: 20000,
        }),
      ]),
    );

    // Admin checks
    await assertStatus('ADMIN users stats', adminClient, '/users/stats', [200]);
    await assertStatus('ADMIN users list', adminClient, '/users', [200]);
    await assertStatus('ADMIN settings', adminClient, '/admin/settings', [200]);

    // Producteur checks
    await assertStatus('PROD me', byRole.PRODUCTEUR, '/auth/me', [200]);
    await assertStatus('PROD parcelles', byRole.PRODUCTEUR, '/parcelles', [200]);
    await assertStatus('PROD capteurs', byRole.PRODUCTEUR, '/capteurs', [200]);
    await assertStatus('PROD alertes', byRole.PRODUCTEUR, '/alertes', [200]);
    await assertStatus('PROD marketplace', byRole.PRODUCTEUR, '/marketplace/produits?limit=5', [200]);

    // Conseiller checks
    await assertStatus('CONS users list', byRole.CONSEILLER, '/users', [200]);
    await assertStatus('CONS producteurs', byRole.CONSEILLER, '/users/producteurs', [200]);
    await assertStatus('CONS analytics', byRole.CONSEILLER, '/analytics/stats', [200]);

    // Acheteur/Fournisseur checks
    await assertStatus('ACHAT marketplace', byRole.ACHETEUR, '/marketplace/produits?limit=5', [200]);
    await assertStatus('FOUR marketplace', byRole.FOURNISSEUR, '/marketplace/produits?limit=5', [200]);

    // AuthZ negative checks
    await assertStatus('PROD forbidden users stats', byRole.PRODUCTEUR, '/users/stats', [403]);
    await assertStatus('ACHAT forbidden admin settings', byRole.ACHETEUR, '/admin/settings', [403]);

    console.table(results);

    const failed = results.filter((r) => !r.ok);
    if (failed.length) {
      console.log('\nFAILED CHECKS:');
      for (const f of failed) {
        console.log(`- ${f.name}: ${f.detail}`);
      }
      process.exit(2);
    }

    console.log('\nALL PLATFORM VALIDATION CHECKS PASSED');
  } catch (error) {
    push('PLATFORM E2E execution', false, error.response?.data?.message || error.message || 'error');
    console.table(results);
    process.exit(1);
  } finally {
    if (tempIds.length) {
      try {
        await prisma.user.updateMany({
          where: { id: { in: tempIds } },
          data: { status: 'INACTIF', updatedAt: new Date() },
        });
      } catch (cleanupError) {
        console.error('Cleanup error:', cleanupError?.message || cleanupError);
      }
    }
    await prisma.$disconnect();
  }
}

run();
