#!/usr/bin/env node

/**
 * AgroSmart - Install All Dependencies
 * =====================================
 * Installs npm deps for backend, frontend, IoT service,
 * and pip deps for the AI service.
 *
 * Usage:
 *   node scripts/install-all.js
 *   npm run install:all
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const ROOT = path.resolve(__dirname, '..');
const RESET = '\x1b[0m';
const GREEN = '\x1b[32m';
const RED = '\x1b[31m';
const BOLD = '\x1b[1m';
const CYAN = '\x1b[36m';

const services = [
  { name: 'Backend',  dir: 'backend',     cmd: 'npm install' },
  { name: 'Frontend', dir: 'frontend',    cmd: 'npm install' },
  { name: 'IoT',      dir: 'iot_service', cmd: 'npm install' },
  { name: 'AI',       dir: 'ai_service',  cmd: 'pip install -r requirements.txt', optional: true },
];

console.log(`\n${GREEN}${BOLD}  🌱  AgroSmart — Installing dependencies${RESET}\n`);

let failures = 0;

for (const svc of services) {
  const cwd = path.join(ROOT, svc.dir);

  if (!fs.existsSync(cwd)) {
    console.log(`${CYAN}[${svc.name}]${RESET} ${RED}Directory not found — skipping${RESET}`);
    continue;
  }

  console.log(`${CYAN}[${svc.name}]${RESET} Running: ${svc.cmd}`);
  try {
    execSync(svc.cmd, { cwd, stdio: 'inherit' });
    console.log(`${CYAN}[${svc.name}]${RESET} ${GREEN}✓ Done${RESET}\n`);
  } catch (err) {
    if (svc.optional) {
      console.log(`${CYAN}[${svc.name}]${RESET} ⚠ Skipped (optional)\n`);
    } else {
      console.log(`${CYAN}[${svc.name}]${RESET} ${RED}✗ Failed${RESET}\n`);
      failures++;
    }
  }
}

if (failures > 0) {
  console.log(`${RED}${BOLD}${failures} service(s) failed to install${RESET}\n`);
  process.exit(1);
} else {
  console.log(`${GREEN}${BOLD}All dependencies installed successfully ✓${RESET}\n`);
}
