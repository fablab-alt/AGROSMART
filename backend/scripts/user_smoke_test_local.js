/* Local user smoke test: login + authenticated user endpoints. */

const base = 'http://localhost:3600/api/v1';

const userIdentifier = process.env.USER_SMOKE_IDENTIFIER || '';
const userPassword = process.env.USER_SMOKE_PASSWORD || '';

async function req(path, opts = {}) {
  const res = await fetch(base + path, opts);
  let bodyText = '';
  try {
    bodyText = await res.text();
  } catch (_) {
    bodyText = '';
  }
  return { ok: res.ok, status: res.status, bodyText };
}

(async () => {
  if (!userIdentifier || !userPassword) {
    console.error('Set USER_SMOKE_IDENTIFIER and USER_SMOKE_PASSWORD before running this script.');
    process.exit(1);
  }

  const results = [];
  const push = (name, ok, detail) => results.push({ name, ok, detail });

  const login = await req('/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier: userIdentifier, password: userPassword }),
  });

  if (!login.ok) {
    push('LOGIN user', false, `status=${login.status} body=${login.bodyText.slice(0, 200)}`);
    console.table(results);
    process.exit(2);
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
    process.exit(3);
  }

  push('LOGIN user', true, 'token obtained');

  const h = { Authorization: `Bearer ${token}` };

  const tests = [
    ['/auth/me', 'GET auth me'],
    ['/messages/unread', 'GET messages unread'],
    ['/messages/notifications', 'GET messages notifications'],
    ['/marketplace/produits?limit=5', 'GET marketplace produits'],
  ];

  for (const [path, name] of tests) {
    const r = await req(path, { headers: h });
    push(name, r.ok, `status=${r.status}`);
  }

  console.table(results);

  const failed = results.filter((r) => !r.ok);
  if (failed.length) {
    console.log('\nFAILED TESTS:');
    for (const f of failed) {
      console.log(`- ${f.name}: ${f.detail}`);
    }
    process.exit(4);
  }

  console.log('\nALL USER TESTS PASSED');
})();
