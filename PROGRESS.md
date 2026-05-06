# AgroSmart — Audit & Optimisation : Résumé de Progression

> Dernière mise à jour : 2026-05-06  
> Branche : `Stone/great-bartik-f19baf`  
> Auteur : Claude Opus 4.7 (audit automatisé multi-sessions)

---

## Statut global

| Phase | Description | Statut |
|-------|-------------|--------|
| Phase 1 | Hotfix sécurité (20 items) | ✅ Terminé |
| Phase 2 | Hardening sécurité (~65 % fait) | 🔄 En cours |
| Phase 3 | Tests automatisés | ❌ Non démarré |
| Perfs backend | Redis ✅, queues, indexes | 🔄 Partiel |
| Perfs frontend | Dashboard ✅, SSC, lazy, PWA | 🔄 Partiel |

---

## ✅ Phase 1 — Hotfix sécurité (TERMINÉ)

### Backend (`backend/src/`)

| Fichier | Changement |
|---------|-----------|
| `server.js` | `hpp()` branché, cookies signés, CORS localhost retiré en prod, bypass ALLOW_DEMO_START supprimé |
| `config/index.js` | JWT_SECRET ≥ 64 chars, COOKIE_SECRET ≥ 32, rate limit 2000 → 300 req/min, COOKIE_SECRET requis en prod |
| `controllers/*.js` | Plafond pagination `Math.min(limit, 100)` dans 10 controllers |
| `services/authService.js` | Statut initial `EN_ATTENTE` — OTP obligatoire avant activation |
| `routes/upload.js` | Whitelist MIME stricte par fieldname + **magic-byte validation** (`file-type@16`) |
| `middlewares/csrf.js` | **NOUVEAU** — Protection CSRF double-submit cookie (64 hex chars, timingSafeEqual) |
| `server.js` | CSRF middleware branché `/api/v1`, endpoint `/api/v1/csrf-token` |
| `utils/logger.js` | Redaction PII : champs sensibles `[REDACTED]`, emails/phones partiellement masqués |

### AI Service (`ai_service/`)

| Fichier | Changement |
|---------|-----------|
| `app.py` | Flask-CORS restrictif (whitelist origins), auth `X-Internal-Token`, `app.run()` bloqué en prod |
| `requirements.txt` | `flask-cors==5.0.0` ajouté |

### IoT Service (`iot_service/`)

| Fichier | Changement |
|---------|-----------|
| `index.js` | Broker public interdit en prod, creds MQTT obligatoires, validation topic, limite 4KB payload, schéma JSON, rate-limit 100 msg/min/device |

### Frontend (`frontend/`)

| Fichier | Changement |
|---------|-----------|
| `next.config.mjs` | Headers sécurité : HSTS, X-Frame-Options DENY, CSP, Referrer-Policy, Permissions-Policy |
| `next.config.mjs` | `typescript.ignoreBuildErrors: false` |

### Mobile / Infra

| Fichier | Changement |
|---------|-----------|
| `environment_config.dart` | Timeouts 30s/60s unifié (réseau rural CI) |
| `docker-compose.yml` | `COOKIE_SECRET` et `AI_INTERNAL_TOKEN` ajoutés |
| `.env.example` | Secrets avec `openssl rand`, valeurs `change_me`, MQTT vars, AI token |

---

## ✅ Phase 2 — Hardening (TERMINÉ en partie)

### Frontend

| Fichier | Changement |
|---------|-----------|
| `src/lib/api.ts` | Purge Zustand (`useAuthStore.getState().logout()`) avant redirect 401 — plus de fuite de contexte utilisateur |
| `app/error.tsx` | **NOUVEAU** — Page d'erreur globale Next.js avec bouton retry + digest |
| `app/not-found.tsx` | **NOUVEAU** — Page 404 avec navigation retour et bouton dashboard |
| `(dashboard)/dashboard/page.tsx` | 7 fetchs séquentiels → `Promise.allSettled` parallèle (-70 % temps chargement dashboard) |

### Backend — Redis & Rate-Limit

| Fichier | Changement |
|---------|-----------|
| `config/redis.js` | **NOUVEAU** — Client ioredis optionnel avec reconnect/fallback gracieux |
| `middlewares/rateLimiter.js` | Store Redis via `rate-limit-redis` quand `REDIS_URL` défini, fallback mémoire |
| `middlewares/security.js` | Brute-force store migré vers Redis (`bfGet/bfSet/bfDel`) + `trackLoginAttempt` async |
| `docker-compose.yml` | Service Redis 7-alpine ajouté (128MB maxmemory, allkeys-lru, healthcheck) |
| `.env.example` | `REDIS_URL=` documenté |

### Backend — Auth & Token Rotation

| Fichier | Changement |
|---------|-----------|
| `prisma/schema.prisma` | Champ `replacedBy` ajouté au modèle `RefreshToken` |
| `middlewares/auth.js` | Détection réutilisation token révoqué → révocation globale + log sécurité |
| `middlewares/auth.js` | `generateRefreshToken(userId, { oldTokenId })` — rotation atomique avec `replacedBy` |
| `controllers/authController.js` | Rotation simplifiée : `generateRefreshToken(user.id, { oldTokenId })` |

### Backend — RBAC Ownership

| Fichier | Changements |
|---------|-----------|
| `controllers/parcellesController.js` | Ownership check sur `getById`, `update`, `delete` pour PRODUCTEUR |
| `controllers/alertesController.js` | Ownership check sur `getById`, `markAsRead` pour PRODUCTEUR |
| `controllers/capteursController.js` | Ownership check via parcelle sur `getStationById`, `updateStation`, `deleteStation` |

### CI/CD

| Fichier | Changement |
|---------|-----------|
| `.github/workflows/security.yml` | **NOUVEAU** — CodeQL (JS+Python), Trivy Docker, npm audit HIGH+, pip-audit, Gitleaks |
| `.github/workflows/ci.yml` | `npm audit` rendu bloquant sur HIGH+ (suppression `|| true`) |

---

## 🔄 Phase 2 — Restant

| # | Action | Fichiers | Priorité |
|---|--------|----------|----------|
| P2-28 | ClamAV side-car antivirus | `docker-compose.yml` | FAIBLE |
| P2-29 | Certificate pinning Flutter avec vrais fingerprints | `environment_config.dart` | HAUTE (avant prod) |
| P2-25 | Modèle `AuditLog` Prisma + middleware audit | `prisma/schema.prisma`, `middlewares/audit.js` | MOYENNE |

---

## ❌ Phase 3 — Tests (NON DÉMARRÉ)

| # | Action | Cible |
|---|--------|-------|
| 34 | Jest + supertest backend | Couverture ≥ 80 % sur auth/parcelles/uploads |
| 35 | Tests unitaires Flutter | Repositories, blocs |
| 36 | Vitest/Jest frontend | Login, Dashboard, ProtectedRoute |
| 37 | pytest AI service | Mock TF, endpoints |
| 38 | Playwright e2e | signup→OTP→login→parcelle→capteur→alerte |
| 39 | OWASP ZAP nightly | CI scheduled |

---

## ❌ Performance & DevOps (NON DÉMARRÉ / PARTIEL)

### Backend
- [ ] ETag/304 sur GETs idempotents
- [ ] Index Prisma : `Mesure(capteurId, timestamp DESC)`, `Alerte(userId, createdAt DESC)`
- [ ] Worker `sensorWorker.js` à activer (déjà présent, pas branché)
- [ ] BullMQ : queues async pour emails/SMS/IA/Sharp
- [ ] Sharp : pipeline upload → resize 3 tailles + WebP

### Frontend
- [ ] Socket.io client : alertes/mesures live (installé, inutilisé)
- [ ] Server Components : pages liste (formations, marketplace)
- [ ] `dynamic(import(...))` sur recharts, framer-motion
- [ ] `next/image` partout + lazy
- [ ] PWA / Service Worker (offline zones rurales CI)

### Mobile
- [ ] Cache offline Isar : TTL par entité
- [ ] Compression images avant upload (`flutter_image_compress`)
- [ ] Préchargement météo au démarrage

### AI Service
- [ ] Gunicorn CMD dans Dockerfile
- [ ] Quantization TFLite
- [ ] Cache résultats par hash image (Redis)

### Infra
- [ ] PM2 cluster mode (`exec_mode: 'cluster'`) dans `ecosystem.config.js`
- [ ] Sentry (backend + frontend + mobile)
- [ ] Loki + Grafana
- [ ] Backup MySQL daily → S3
- [ ] Healthcheck `/readiness` distinct (vérifie DB + Redis + AI)

---

## Vérifications rapides

```bash
# Vérifications Phase 1/2
grep -c "timingSafeEqual" backend/src/middlewares/csrf.js        # → 1
grep -c "validateMagicBytes" backend/src/routes/upload.js        # → 2
grep -c "Promise.allSettled" "frontend/src/app/(dashboard)/dashboard/page.tsx"  # → 1
grep -c "redisClient" backend/src/middlewares/rateLimiter.js     # → 1
grep -c "replacedBy" backend/prisma/schema.prisma                # → 1
grep -c "REFRESH_TOKEN_REUSE" backend/src/middlewares/auth.js    # → 1

# Démarrer en local
npm run dev  # depuis la racine

# Tests sécurité backend
cd backend && npm run test:security
```

---

## Prochaine session — reprendre à

1. **Phase 3 — Tests** : `cd backend && npm init jest` → écrire tests supertest pour `auth/login`, `auth/register`, `uploads`
2. **Perfs backend** : activer `sensorWorker.js` dans `server.js`, ajouter indexes Prisma, ETag sur GETs
3. **Frontend** : supprimer `socket.io-client` si non utilisé ou implémenter alertes live
4. **Mobile** : confirmer HTTPS forcé en dev + commencer Flutter tests
