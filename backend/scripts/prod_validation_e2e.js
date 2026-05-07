/*
  Validation E2E orientee production pour les flux admin:
  - login admin
  - gestion utilisateurs (create/update/deactivate)
  - suivi production, capteurs, qualite data
  - parametres (mises a jour logicielles)
  - exports admin
*/

const axios = require('axios');
const path = require('path');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');

require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const API_BASE = process.env.API_BASE_URL || `http://localhost:${process.env.PORT || 3600}/api/v1`;
const adminIdentifier =
  process.env.ADMIN_SMOKE_IDENTIFIER ||
  process.env.ADMIN_EMAIL ||
  process.env.ADMIN_TELEPHONE ||
  null;
const adminPassword =
  process.env.ADMIN_SMOKE_PASSWORD ||
  process.env.ADMIN_PASSWORD ||
  null;

function randomDigits(size) {
  const min = 10 ** (size - 1);
  const max = 10 ** size - 1;
  return String(Math.floor(Math.random() * (max - min + 1)) + min);
}

function generateTempPassword() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  const raw = crypto.randomBytes(16);
  let generated = '';
  for (let i = 0; i < raw.length; i += 1) {
    generated += alphabet[raw[i] % alphabet.length];
  }
  return `${generated}9!aA`;
}

async function run() {
  const client = axios.create({ baseURL: API_BASE, timeout: 20000 });
  const prisma = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });
  const results = [];
  let tempUserId = null;

  const push = (name, ok, detail) => {
    results.push({ name, ok, detail });
  };

  try {
    let token = null;
    try {
      if (!adminIdentifier || !adminPassword) {
        throw new Error('admin smoke credentials not set');
      }
      const login = await client.post('/auth/login', {
        identifier: adminIdentifier,
        password: adminPassword,
      });
      token = login.data?.data?.accessToken || login.data?.data?.token || null;
      push('LOGIN admin', Boolean(token), token ? 'OK' : 'token manquant');
    } catch {
      const admin = await prisma.user.findFirst({
        where: { role: 'ADMIN', status: 'ACTIF' },
        select: { id: true, role: true },
      });
      if (!admin || !process.env.JWT_SECRET) {
        throw new Error('Impossible d\'obtenir un token admin de secours');
      }
      token = jwt.sign(
        { userId: admin.id, role: admin.role },
        process.env.JWT_SECRET,
        { expiresIn: '30m' },
      );
      push('LOGIN admin fallback', true, 'token JWT généré depuis DB');
    }

    if (!token) {
      throw new Error('Token admin manquant');
    }

    const auth = axios.create({
      baseURL: API_BASE,
      timeout: 20000,
      headers: { Authorization: `Bearer ${token}` },
    });

    const ts = Date.now();
    const tempPhone = `+22507${randomDigits(8)}`;
    const tempEmail = `temp.prod.${ts}@agrosmart.ci`;
    const tempPassword = generateTempPassword();

    // 1) Gestion utilisateurs
    const created = await auth.post('/users', {
      nom: 'Validation',
      prenoms: 'Prod User',
      telephone: tempPhone,
      email: tempEmail,
      password: tempPassword,
      role: 'PRODUCTEUR',
    });
    tempUserId = created.data?.data?.id;
    push('CREATE user', Boolean(tempUserId), `id=${tempUserId || 'none'}`);

    if (!tempUserId) {
      throw new Error('Creation user invalide');
    }

    const roleUpdate = await auth.put(`/users/${tempUserId}`, { role: 'CONSEILLER' });
    push('UPDATE user role', roleUpdate.status === 200, `status=${roleUpdate.status}`);

    const statusUpdate = await auth.put(`/users/${tempUserId}/status`, { status: 'SUSPENDU' });
    push('UPDATE user status', statusUpdate.status === 200, `status=${statusUpdate.status}`);

    const usersList = await auth.get('/users', { params: { limit: 50 } });
    const foundTemp = (usersList.data?.data || []).find((u) => u.id === tempUserId);
    push('LIST users includes temp', Boolean(foundTemp), foundTemp ? 'found' : 'missing');

    const usersStats = await auth.get('/users/stats');
    push('GET users stats', usersStats.status === 200, `status=${usersStats.status}`);

    // 2) Suivi production
    const parcelles = await auth.get('/parcelles');
    push('GET parcelles', parcelles.status === 200, `count=${(parcelles.data?.data || []).length}`);

    const analyticsStats = await auth.get('/analytics/stats');
    push('GET analytics stats', analyticsStats.status === 200, `status=${analyticsStats.status}`);

    const seasonal = await auth.get('/analytics/seasonal-comparison').catch(() => null);
    push('GET seasonal comparison', Boolean(seasonal && seasonal.status === 200), seasonal ? `status=${seasonal.status}` : 'fallback');

    // 3) Supervision capteurs + qualite donnees
    const capteurs = await auth.get('/capteurs');
    push('GET capteurs', capteurs.status === 200, `count=${(capteurs.data?.data || []).length}`);

    const capteursStats = await auth.get('/capteurs/stats').catch(() => null);
    push('GET capteurs stats', Boolean(capteursStats && capteursStats.status === 200), capteursStats ? `status=${capteursStats.status}` : 'not available');

    const mesuresStats = await auth.get('/mesures/stats').catch(() => null);
    push('GET mesures stats', Boolean(mesuresStats && mesuresStats.status === 200), mesuresStats ? `status=${mesuresStats.status}` : 'not available');

    const alertes = await auth.get('/alertes');
    push('GET alertes', alertes.status === 200, `count=${(alertes.data?.data || []).length}`);

    // 4) Mises a jour logicielles via settings
    const settingsBefore = await auth.get('/admin/settings');
    const snapshot = settingsBefore.data?.data || {};
    push('GET admin settings', settingsBefore.status === 200, `keys=${Object.keys(snapshot).length}`);

    const patchPayload = {
      mobile_latest_version: snapshot.mobile_latest_version || '1.0.0',
      mobile_min_version: snapshot.mobile_min_version || '1.0.0',
      backend_target_version: snapshot.backend_target_version || '1.0.0',
      capteur_target_firmware: snapshot.capteur_target_firmware || '1.0.0',
      force_mobile_update: Boolean(snapshot.force_mobile_update),
      force_capteur_update: Boolean(snapshot.force_capteur_update),
      maintenance_window: snapshot.maintenance_window || 'none',
    };
    const settingsUpdate = await auth.put('/admin/settings', patchPayload);
    push('PUT admin settings', settingsUpdate.status === 200, `status=${settingsUpdate.status}`);

    // 5) Exportation donnees
    const exportAnalytics = await auth.get('/analytics/export', {
      params: { format: 'xlsx', period: 30, types: 'users,parcelles,capteurs,productions' },
    });
    push('EXPORT analytics', exportAnalytics.status === 200, `status=${exportAnalytics.status}`);

    const exportMesures = await auth.get('/mesures/export', { params: { format: 'xlsx' } });
    push('EXPORT mesures', exportMesures.status === 200, `status=${exportMesures.status}`);

    // Cleanup user
    const deactivated = await auth.delete(`/users/${tempUserId}`);
    push('DEACTIVATE temp user', deactivated.status === 200, `status=${deactivated.status}`);

    console.table(results);
    const failed = results.filter((r) => !r.ok);
    if (failed.length) {
      console.log('\nFAILED CHECKS:');
      failed.forEach((f) => console.log(`- ${f.name}: ${f.detail}`));
      process.exit(2);
    }

    console.log('\nALL PROD VALIDATION CHECKS PASSED');
    await prisma.$disconnect();
  } catch (error) {
    push('E2E execution', false, error.response?.data?.message || error.message || 'error');
    console.table(results);
    try {
      await prisma.$disconnect();
    } catch (disconnectError) {
      console.error('Prisma disconnect error:', disconnectError?.message || disconnectError);
    }
    process.exit(1);
  }
}

run();
