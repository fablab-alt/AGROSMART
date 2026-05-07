/* Local admin smoke test: login + key admin endpoints used by frontend admin pages. */

const base = 'http://localhost:3600/api/v1';
const frontendBase = 'http://localhost:3603';
const adminIdentifier = process.env.ADMIN_SMOKE_IDENTIFIER || process.env.ADMIN_EMAIL || process.env.ADMIN_TELEPHONE || '';
const adminPassword = process.env.ADMIN_SMOKE_PASSWORD || process.env.ADMIN_PASSWORD || '';

async function req(path, opts = {}) {
  const res = await fetch(base + path, opts);
  let bodyText = '';
  try {
    bodyText = await res.text();
  } catch (_) {
    bodyText = '';
  }
  return { ok: res.ok, status: res.status, bodyText, headers: res.headers };
}

(async () => {
  const results = [];
  const push = (name, ok, detail) => results.push({ name, ok, detail });

  if (!adminIdentifier || !adminPassword) {
    push('LOGIN admin', false, 'Set ADMIN_SMOKE_IDENTIFIER and ADMIN_SMOKE_PASSWORD (or ADMIN_PASSWORD) before running.');
    console.table(results);
    process.exit(1);
  }

  const login = await req('/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier: adminIdentifier, password: adminPassword }),
  });

  if (!login.ok) {
    push('LOGIN admin', false, `status=${login.status} body=${login.bodyText.slice(0, 200)}`);
    console.table(results);
    process.exit(1);
  }

  let token = '';
  try {
    token = JSON.parse(login.bodyText).data.accessToken || '';
  } catch (_) {
    token = '';
  }

  if (!token) {
    push('LOGIN token extraction', false, `body=${login.bodyText.slice(0, 200)}`);
    console.table(results);
    process.exit(1);
  }

  push('LOGIN admin', true, 'token obtained');
  const h = { Authorization: `Bearer ${token}` };

  const tests = [
    ['/users/stats', 'GET users stats'],
    ['/users?role=producteur', 'GET users list filtered'],
    ['/users/producteurs', 'GET producteurs'],
    ['/users', 'GET users admin list'],
    ['/parcelles', 'GET parcelles'],
    ['/capteurs', 'GET capteurs'],
    ['/alertes', 'GET alertes'],
    ['/mesures', 'GET mesures'],
    ['/cultures', 'GET cultures'],
    ['/analytics/stats', 'GET analytics stats'],
    ['/admin/settings', 'GET admin settings'],
  ];

  const payloads = {};
  for (const [path, name] of tests) {
    const r = await req(path, { headers: h });
    push(name, r.ok, `status=${r.status}`);
    payloads[path] = r.bodyText;
  }

  const putSettings = await req('/admin/settings', {
    method: 'PUT',
    headers: { ...h, 'Content-Type': 'application/json' },
    body: JSON.stringify({ maintenance_mode: false }),
  });
  push('PUT admin settings', putSettings.ok, `status=${putSettings.status}`);

  const exportAnalytics = await req('/analytics/export?format=xlsx&period=30&types=users,parcelles', {
    headers: h,
  });
  push('GET analytics export', exportAnalytics.ok, `status=${exportAnalytics.status}`);

  const exportMesures = await req('/mesures/export?format=xlsx', { headers: h });
  push('GET mesures export', exportMesures.ok, `status=${exportMesures.status}`);

  let users = [];
  try {
    users = JSON.parse(payloads['/users'] || '{}').data || [];
  } catch (_) {
    users = [];
  }
  const targetUser = users.find((u) => u.role !== 'ADMIN');
  if (targetUser && targetUser.id) {
    const upd = await req(`/users/${targetUser.id}/status`, {
      method: 'PUT',
      headers: { ...h, 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: 'ACTIF' }),
    });
    push('PUT user status', upd.ok, `status=${upd.status} userId=${targetUser.id}`);

    const getById = await req(`/users/${targetUser.id}`, { headers: h });
    push('GET user detail', getById.ok, `status=${getById.status}`);
  } else {
    push('PUT user status', true, 'SKIPPED (no non-admin user found)');
    push('GET user detail', true, 'SKIPPED (no non-admin user found)');
  }

  let capteurs = [];
  try {
    capteurs = JSON.parse(payloads['/capteurs'] || '{}').data || [];
  } catch (_) {
    capteurs = [];
  }

  const targetCapteur = capteurs[0];
  if (targetCapteur && targetCapteur.id) {
    const updCapteur = await req(`/capteurs/${targetCapteur.id}`, {
      method: 'PUT',
      headers: { ...h, 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: 'MAINTENANCE' }),
    });
    push('PUT capteur status MAINTENANCE', updCapteur.ok, `status=${updCapteur.status} capteurId=${targetCapteur.id}`);

    const restoreCapteur = await req(`/capteurs/${targetCapteur.id}`, {
      method: 'PUT',
      headers: { ...h, 'Content-Type': 'application/json' },
      body: JSON.stringify({ status: 'ACTIF' }),
    });
    push('PUT capteur status ACTIF restore', restoreCapteur.ok, `status=${restoreCapteur.status} capteurId=${targetCapteur.id}`);
  } else {
    push('PUT capteur status MAINTENANCE', true, 'SKIPPED (no capteur found)');
    push('PUT capteur status ACTIF restore', true, 'SKIPPED (no capteur found)');
  }

  let frontendLoginOk = false;
  let frontendAdminOk = false;
  try {
    const f1 = await fetch(frontendBase + '/login');
    frontendLoginOk = f1.ok;
    push('FRONTEND /login reachable', f1.ok, `status=${f1.status}`);
  } catch (e) {
    push('FRONTEND /login reachable', false, e.message);
  }

  try {
    const f2 = await fetch(frontendBase + '/admin');
    frontendAdminOk = f2.ok;
    push('FRONTEND /admin reachable', f2.ok, `status=${f2.status}`);
  } catch (e) {
    push('FRONTEND /admin reachable', false, e.message);
  }

  console.table(results);

  const failed = results.filter((r) => !r.ok);
  if (failed.length) {
    console.log('\nFAILED TESTS:');
    for (const f of failed) {
      console.log(`- ${f.name}: ${f.detail}`);
    }
    process.exit(2);
  }

  if (!frontendLoginOk || !frontendAdminOk) {
    process.exit(3);
  }

  console.log('\nALL ADMIN TESTS PASSED');
})();
