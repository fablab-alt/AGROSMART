# ============================================================
# BACKEND — builder
# ============================================================
FROM node:22-bookworm-slim AS backend-builder
WORKDIR /app/backend

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY backend/package*.json ./
RUN npm ci

COPY backend/prisma ./prisma
RUN npx prisma generate

COPY backend/src ./src
COPY backend/scripts ./scripts
COPY backend/package.json ./package.json

RUN npm prune --omit=dev && npm cache clean --force

# ============================================================
# BACKEND — runtime
# ============================================================
FROM node:22-bookworm-slim AS backend-runtime
ENV NODE_ENV=production
WORKDIR /app/backend

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=backend-builder /app/backend/node_modules ./node_modules
COPY --from=backend-builder /app/backend/prisma      ./prisma
COPY --from=backend-builder /app/backend/src         ./src
COPY --from=backend-builder /app/backend/scripts     ./scripts
COPY --from=backend-builder /app/backend/package.json ./package.json

# Entrypoint script (handles MySQL wait + migrations + seed + start)
COPY backend/entrypoint.prod.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

RUN mkdir -p uploads logs && chown -R node:node /app/backend

USER node
EXPOSE 3600
ENTRYPOINT ["./entrypoint.sh"]

# ============================================================
# BACKEND WORKER — same base, different CMD
# ============================================================
FROM backend-runtime AS backend-worker-runtime
ENTRYPOINT []
CMD ["node", "src/worker.js"]

# ============================================================
# FRONTEND — production dependencies (lightweight set)
# ============================================================
FROM node:22-bookworm-slim AS frontend-prod-deps
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci --omit=dev

# ============================================================
# FRONTEND — builder
# ============================================================
FROM node:22-bookworm-slim AS frontend-builder
WORKDIR /app/frontend

COPY frontend/package*.json ./
RUN npm ci

COPY frontend/ ./

ARG NEXT_PUBLIC_API_URL
ARG NEXT_PUBLIC_SOCKET_URL

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
ENV NEXT_PUBLIC_SOCKET_URL=${NEXT_PUBLIC_SOCKET_URL}

RUN npm run build && npm cache clean --force

# ============================================================
# FRONTEND — runtime (standalone output)
# ============================================================
FROM node:22-bookworm-slim AS frontend-runtime
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
WORKDIR /app/frontend

# standalone bundles server.js + minimal node_modules itself
COPY --from=frontend-builder /app/frontend/.next/standalone ./
COPY --from=frontend-builder /app/frontend/.next/static     ./.next/static
COPY --from=frontend-builder /app/frontend/public           ./public

RUN chown -R node:node /app/frontend

USER node
EXPOSE 3603
ENV PORT=3603
ENV HOSTNAME=0.0.0.0
CMD ["node", "server.js"]
