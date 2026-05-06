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
COPY backend/package.json ./package.json

RUN npm prune --omit=dev && npm cache clean --force

FROM node:22-bookworm-slim AS backend-runtime
ENV NODE_ENV=production
WORKDIR /app/backend

RUN apt-get update \
	&& apt-get install -y --no-install-recommends openssl ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=backend-builder /app/backend/node_modules ./node_modules
COPY --from=backend-builder /app/backend/prisma ./prisma
COPY --from=backend-builder /app/backend/src ./src
COPY --from=backend-builder /app/backend/package.json ./package.json

RUN mkdir -p uploads logs && chown -R node:node /app/backend

USER node
EXPOSE 3600
CMD ["node", "src/server.js"]

FROM backend-runtime AS backend-worker-runtime
CMD ["node", "src/worker.js"]

FROM node:22-bookworm-slim AS frontend-prod-deps
WORKDIR /app/frontend

COPY frontend/package*.json ./
RUN npm ci --omit=dev

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

FROM node:22-bookworm-slim AS frontend-runtime
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
WORKDIR /app/frontend

COPY --from=frontend-prod-deps /app/frontend/node_modules ./node_modules
COPY --from=frontend-builder /app/frontend/.next ./.next
COPY --from=frontend-builder /app/frontend/public ./public
COPY --from=frontend-builder /app/frontend/package.json ./package.json
COPY --from=frontend-builder /app/frontend/next.config.mjs ./next.config.mjs

RUN chown -R node:node /app/frontend

USER node
EXPOSE 3603
CMD ["sh", "-c", "node_modules/.bin/next start -p ${PORT:-3603}"]
