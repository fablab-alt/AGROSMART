#!/usr/bin/env node

/**
 * AgroSmart - Development Orchestrator
 * ====================================
 * Launches all services in the correct order with health checks.
 *
 * Architecture (Microservices):
 *   1. Backend   (Node/Express)  → port 3600
 *   2. Frontend  (Next.js)       → port 3603
 *   3. IoT       (Node/MQTT)     → port 4000  (optional — requires MQTT)
 *   4. AI        (Python/Flask)  → port 5001  (optional — requires TensorFlow models)
 *   5. Studio   (Prisma Studio)  → port 5555  (optional — DB explorer)
 *
 * Usage:
 *   node scripts/dev.js              # Launch all services
 *   node scripts/dev.js --no-iot     # Skip IoT service
 *   node scripts/dev.js --no-ai      # Skip AI service
 *   node scripts/dev.js --no-studio  # Skip Prisma Studio
 *   node scripts/dev.js --backend    # Backend only
 */

const { spawn } = require('child_process');
const path = require('path');
const http = require('http');
const fs = require('fs');

// ===================================================
// Configuration
// ===================================================

const ROOT = path.resolve(__dirname, '..');
const args = process.argv.slice(2);

const SERVICES = {
  backend: {
    name: 'Backend',
    color: '\x1b[32m',    // green
    cmd: 'npx',
    args: ['nodemon', 'src/server.js'],
    cwd: path.join(ROOT, 'backend'),
    port: 3600,
    healthUrl: 'http://localhost:3600/health',
    required: true,
    enabled: !args.includes('--no-backend'),
  },
  frontend: {
    name: 'Frontend',
    color: '\x1b[34m',    // blue
    cmd: 'npx',
    args: ['next', 'dev', '-p', '3603'],
    cwd: path.join(ROOT, 'frontend'),
    port: 3603,
    healthUrl: null,
    required: true,
    enabled: !args.includes('--no-frontend') && !args.includes('--backend'),
  },
  iot: {
    name: 'IoT',
    color: '\x1b[35m',    // magenta
    cmd: 'node',
    args: ['index.js'],
    cwd: path.join(ROOT, 'iot_service'),
    port: 4000,
    healthUrl: 'http://localhost:4000/health',
    required: false,
    enabled: !args.includes('--no-iot') && !args.includes('--backend'),
  },
  ai: {
    name: 'AI',
    color: '\x1b[33m',    // yellow
    cmd: 'python3',
    args: ['app.py'],
    cwd: path.join(ROOT, 'ai_service'),
    port: 5001,
    healthUrl: 'http://localhost:5001/health',
    required: false,
    enabled: !args.includes('--no-ai') && !args.includes('--backend'),
  },
  studio: {
    name: 'Studio',
    color: '\x1b[36m',    // cyan
    cmd: 'npx',
    args: ['prisma', 'studio', '--port', '5555'],
    cwd: path.join(ROOT, 'backend'),
    port: 5555,
    healthUrl: null,
    required: false,
    enabled: !args.includes('--no-studio') && !args.includes('--backend'),
  },
};

const RESET = '\x1b[0m';
const BOLD = '\x1b[1m';
const DIM = '\x1b[2m';
const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const CYAN = '\x1b[36m';

// ===================================================
// Helpers
// ===================================================

function log(service, msg) {
  const svc = SERVICES[service];
  const tag = svc ? `${svc.color}[${svc.name}]${RESET}` : `${CYAN}[System]${RESET}`;
  console.log(`${tag} ${msg}`);
}

function banner() {
  console.log(`
${GREEN}${BOLD}╔══════════════════════════════════════════════════╗
║            🌱  AgroSmart Dev Server  🌱           ║
╚══════════════════════════════════════════════════╝${RESET}
`);
}

function isPortInUse(port) {
  return new Promise((resolve) => {
    const server = require('net').createServer();
    server.once('error', () => resolve(true));
    server.once('listening', () => { server.close(); resolve(false); });
    server.listen(port);
  });
}

function checkHealth(url, timeout = 3000) {
  return new Promise((resolve) => {
    const req = http.get(url, { timeout }, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve({ ok: res.statusCode === 200, data: json });
        } catch {
          resolve({ ok: res.statusCode === 200, data: null });
        }
      });
    });
    req.on('error', () => resolve({ ok: false, data: null }));
    req.on('timeout', () => { req.destroy(); resolve({ ok: false, data: null }); });
  });
}

async function waitForService(key, maxRetries = 30) {
  const svc = SERVICES[key];
  if (!svc.healthUrl) return true;

  for (let i = 0; i < maxRetries; i++) {
    const { ok } = await checkHealth(svc.healthUrl);
    if (ok) {
      log(key, `${GREEN}✓ Ready on port ${svc.port}${RESET}`);
      return true;
    }
    await new Promise((r) => setTimeout(r, 1000));
  }
  return false;
}

function checkPrerequisites(key) {
  const svc = SERVICES[key];
  if (!fs.existsSync(svc.cwd)) {
    log(key, `${RED}✗ Directory not found: ${svc.cwd}${RESET}`);
    return false;
  }

  // Check node_modules for Node services
  if (svc.cmd !== 'python3') {
    const nodeModules = path.join(svc.cwd, 'node_modules');
    if (!fs.existsSync(nodeModules)) {
      log(key, `${RED}✗ node_modules missing — run: npm run install:all${RESET}`);
      return false;
    }
  }

  return true;
}

// ===================================================
// Process Management
// ===================================================

const children = [];

function spawnService(key) {
  const svc = SERVICES[key];
  const tag = `${svc.color}[${svc.name}]${RESET}`;

  log(key, `Starting on port ${svc.port}...`);

  const child = spawn(svc.cmd, svc.args, {
    cwd: svc.cwd,
    stdio: ['ignore', 'pipe', 'pipe'],
    env: { ...process.env, PORT: String(svc.port), NODE_ENV: 'development', FORCE_COLOR: '1' },
  });

  child.stdout.on('data', (data) => {
    data.toString().trim().split('\n').forEach((line) => {
      console.log(`${tag} ${line}`);
    });
  });

  child.stderr.on('data', (data) => {
    data.toString().trim().split('\n').forEach((line) => {
      console.log(`${tag} ${DIM}${line}${RESET}`);
    });
  });

  child.on('exit', (code, signal) => {
    if (signal !== 'SIGTERM' && signal !== 'SIGINT') {
      log(key, `${RED}Process exited (code=${code}, signal=${signal})${RESET}`);
    }
  });

  children.push({ key, child });
  return child;
}

function shutdown() {
  console.log(`\n${CYAN}[System]${RESET} Shutting down all services...`);
  children.forEach(({ key, child }) => {
    log(key, 'Stopping...');
    child.kill('SIGTERM');
  });
  setTimeout(() => {
    children.forEach(({ child }) => {
      if (!child.killed) child.kill('SIGKILL');
    });
    process.exit(0);
  }, 3000);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

// ===================================================
// Main
// ===================================================

async function main() {
  banner();

  const enabledServices = Object.keys(SERVICES).filter((k) => SERVICES[k].enabled);

  console.log(`${CYAN}[System]${RESET} Services to launch: ${enabledServices.map((k) => SERVICES[k].name).join(', ')}\n`);

  // 1. Pre-flight checks
  for (const key of enabledServices) {
    const portBusy = await isPortInUse(SERVICES[key].port);
    if (portBusy) {
      log(key, `${RED}✗ Port ${SERVICES[key].port} already in use${RESET}`);
      if (SERVICES[key].required) {
        console.log(`${RED}   → Kill the process on port ${SERVICES[key].port} and retry${RESET}`);
        process.exit(1);
      }
      SERVICES[key].enabled = false;
      continue;
    }
    if (!checkPrerequisites(key)) {
      if (SERVICES[key].required) process.exit(1);
      SERVICES[key].enabled = false;
    }
  }

  // 2. Start backend first (other services may depend on it)
  if (SERVICES.backend.enabled) {
    spawnService('backend');
    const ready = await waitForService('backend');
    if (!ready) {
      log('backend', `${RED}✗ Failed to start — check logs above${RESET}`);
      shutdown();
      return;
    }
  }

  // 3. Start remaining services in parallel
  const parallel = enabledServices.filter((k) => k !== 'backend' && SERVICES[k].enabled);
  parallel.forEach((key) => spawnService(key));

  // 4. Wait for optional services (non-blocking)
  for (const key of parallel) {
    if (SERVICES[key].healthUrl) {
      waitForService(key, 15).then((ok) => {
        if (!ok) log(key, `${DIM}⚠ Service did not become healthy (optional)${RESET}`);
      });
    }
  }

  // 5. Summary
  setTimeout(() => {
    console.log(`
${GREEN}${BOLD}═══════════════════════════════════════════════════${RESET}
${GREEN}  AgroSmart is running!${RESET}

  ${BOLD}Backend API:${RESET}    http://localhost:3600
  ${BOLD}API Docs:${RESET}       http://localhost:3600/api-docs
  ${BOLD}Frontend:${RESET}       http://localhost:3603${SERVICES.iot.enabled ? `
  ${BOLD}IoT Service:${RESET}    http://localhost:4000` : ''}${SERVICES.ai.enabled ? `
  ${BOLD}AI Service:${RESET}     http://localhost:5001` : ''}${SERVICES.studio.enabled ? `
  ${BOLD}Prisma Studio:${RESET}  http://localhost:5555` : ''}

  ${DIM}Press Ctrl+C to stop all services${RESET}
${GREEN}═══════════════════════════════════════════════════${RESET}
`);
  }, 3000);
}

main().catch((err) => {
  console.error(`${RED}[System] Fatal error:${RESET}`, err);
  process.exit(1);
});
