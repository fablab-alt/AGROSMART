#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${BACKEND_DIR}"

echo "[1/3] Prisma migrate deploy"
npx prisma migrate deploy

echo "[2/3] Seed admin"
node scripts/seed_admin.js

echo "[3/3] Health check"
HEALTH_PORT="${PORT:-${BACKEND_PORT:-3600}}"
HEALTHCHECK_URL="${HEALTHCHECK_URL:-http://127.0.0.1:${HEALTH_PORT}/health}"

HEALTHCHECK_URL="${HEALTHCHECK_URL}" node -e '
const target = process.env.HEALTHCHECK_URL;
if (!target) {
  console.error("HEALTHCHECK_URL is not defined");
  process.exit(1);
}
const lib = target.startsWith("https") ? require("https") : require("http");
const req = lib.get(target, { timeout: 10000 }, (res) => {
  let body = "";
  res.on("data", (chunk) => { body += chunk; });
  res.on("end", () => {
    if (res.statusCode !== 200) {
      console.error(`[health] unexpected status: ${res.statusCode}`);
      process.exit(1);
    }
    console.log(`[health] ok: ${body}`);
  });
});
req.on("timeout", () => {
  req.destroy(new Error("health check timeout"));
});
req.on("error", (err) => {
  console.error(`[health] failed: ${err.message}`);
  process.exit(1);
});
'

echo "Post-deploy one-shot completed successfully."