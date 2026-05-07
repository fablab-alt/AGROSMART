#!/usr/bin/env node

/**
 * AgroSmart - Health Check CLI
 * =============================
 * Checks the health of all running services.
 *
 * Usage:
 *   node scripts/health-check.js
 *   npm run health
 */

const http = require('http');

const RESET = '\x1b[0m';
const BOLD = '\x1b[1m';
const GREEN = '\x1b[32m';
const RED = '\x1b[31m';
const YELLOW = '\x1b[33m';
const DIM = '\x1b[2m';

const SERVICES = [
  { name: 'Backend',  url: 'http://localhost:3600/health', required: true },
  { name: 'Frontend', url: 'http://localhost:3603',        required: true },
  { name: 'IoT',      url: 'http://localhost:4000/health', required: false },
  { name: 'AI',       url: 'http://localhost:5001/health', required: false },
];

function check(url, timeout = 3000) {
  return new Promise((resolve) => {
    const start = Date.now();
    const req = http.get(url, { timeout }, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => {
        const ms = Date.now() - start;
        try {
          resolve({ ok: res.statusCode < 400, status: res.statusCode, ms, data: JSON.parse(data) });
        } catch {
          resolve({ ok: res.statusCode < 400, status: res.statusCode, ms, data: null });
        }
      });
    });
    req.on('error', () => resolve({ ok: false, status: null, ms: Date.now() - start, data: null }));
    req.on('timeout', () => { req.destroy(); resolve({ ok: false, status: null, ms: timeout, data: null }); });
  });
}

async function main() {
  console.log(`\n${GREEN}${BOLD}  🌱  AgroSmart Health Report${RESET}\n`);
  console.log(`${'Service'.padEnd(12)} ${'Status'.padEnd(12)} ${'Time'.padEnd(10)} Details`);
  console.log(`${'─'.repeat(60)}`);

  let allOk = true;

  for (const svc of SERVICES) {
    const res = await check(svc.url);
    const icon = res.ok ? `${GREEN}✓ UP${RESET}` : `${RED}✗ DOWN${RESET}`;
    const time = res.ok ? `${DIM}${res.ms}ms${RESET}` : `${DIM}-${RESET}`;
    const detail = res.data
      ? `${DIM}${JSON.stringify(res.data).slice(0, 50)}${RESET}`
      : (res.ok ? '' : `${YELLOW}(${svc.required ? 'required' : 'optional'})${RESET}`);

    console.log(`${svc.name.padEnd(12)} ${icon.padEnd(22)} ${time.padEnd(18)} ${detail}`);

    if (!res.ok && svc.required) allOk = false;
  }

  console.log(`${'─'.repeat(60)}`);
  console.log(allOk
    ? `${GREEN}${BOLD}All required services are healthy ✓${RESET}\n`
    : `${RED}${BOLD}Some required services are down ✗${RESET}\n`
  );

  process.exit(allOk ? 0 : 1);
}

main();
