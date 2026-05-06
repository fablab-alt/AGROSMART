# AgroSmart — Audit complet & Plan d'optimisation

> **Date :** 2026-05-06
> **Branche :** `Stone/great-bartik-f19baf`
> **Périmètre :** monorepo complet (backend Node/Express/Prisma, frontend Next.js 16, mobile Flutter, service IA Flask/TensorFlow, service IoT Node/MQTT, infrastructure Docker + nginx + PM2 + GitHub Actions).
> **Méthodologie :** lecture exhaustive du code via 3 agents d'exploration parallèles, reconstitution des parcours utilisateurs, cartographie de la surface d'attaque, analyse statique des dépendances.
> **Couverture :** ~110 fichiers lus, ~70 issues identifiées (8 CRITIQUES, 22 ÉLEVÉES, 25 MOYENNES, ~15 FAIBLES).

---

## Table des matières

1. [Synthèse exécutive](#1-synthèse-exécutive)
2. [Stack technique relevée](#2-stack-technique-relevée)
3. [Workflows utilisateur — cartographie](#3-workflows-utilisateur--cartographie)
4. [Audit Backend (Node/Express/Prisma)](#4-audit-backend)
5. [Audit Frontend (Next.js 16 / React 19)](#5-audit-frontend)
6. [Audit Mobile (Flutter)](#6-audit-mobile)
7. [Audit AI Service (Flask/TensorFlow)](#7-audit-ai-service)
8. [Audit IoT Service (Node/MQTT)](#8-audit-iot-service)
9. [Audit Infrastructure (Docker, nginx, PM2, CI/CD)](#9-audit-infrastructure)
10. [Top 10 risques bloquants](#10-top-10-risques-bloquants)
11. [Plan de correction des bugs (Phase 1, 2, 3)](#11-plan-de-correction-des-bugs)
12. [Plan d'optimisation performance](#12-plan-doptimisation-performance)
13. [Plan UX](#13-plan-ux)
14. [Plan DevOps & observabilité](#14-plan-devops--observabilité)
15. [Procédure de test & critères d'acceptation](#15-procédure-de-test--critères-dacceptation)
16. [Roadmap consolidée 12 semaines](#16-roadmap-consolidée-12-semaines)
17. [Référence rapide — fichiers à modifier](#17-référence-rapide--fichiers-à-modifier)

---

## 1. Synthèse exécutive

| Composant | Sécurité | Performance | Qualité (tests, doc) |
|-----------|:-------:|:-----------:|:--------------------:|
| Backend Express/Prisma     | 6.5/10 | 6/10 | 5/10 (0 % tests) |
| Frontend Next.js 16        | 6/10   | 6/10 | 6/10 |
| Mobile Flutter             | 5.5/10 | 7/10 | 6/10 |
| AI Service Flask           | 4/10   | 5/10 | 4/10 |
| IoT Service                | 4/10   | 6/10 | 5/10 |
| Infra (Docker/nginx/PM2)   | 6/10   | 7/10 | 6/10 |

**3 risques bloquants production :**
1. Le service IA Flask tourne via `app.run()` (serveur de développement) — pas de WSGI.
2. Le backend a un drapeau `ALLOW_DEMO_START` qui permet de démarrer sans base de données.
3. Aucune protection CSRF ; rate-limit en mémoire (perdue au redémarrage) et plafond global trop permissif (2 000 req/min).

**Forces du projet :**
- Architecture monorepo claire, séparation backend/frontend/mobile/services bien définie.
- Cookies HttpOnly + SameSite=strict (PR récents).
- Schéma Prisma complet avec ~100 index.
- Nombreux scripts d'audit déjà prévus (`security-audit.js`, `prod_validation_e2e.js`).
- Docker Compose et PM2 fonctionnels, CI GitHub Actions en place.

---

## 2. Stack technique relevée

**Backend** : Node ≥ 20, Express 5.2.1, Prisma 6.9, MariaDB/MySQL, JWT (HS256), bcryptjs (12 rounds), Socket.IO 4.8, helmet 8, cors, hpp (présent mais non utilisé), express-rate-limit 8, express-validator 7, multer 2, sharp (importé jamais utilisé), nodemailer, twilio, winston + winston-daily-rotate-file.

**Frontend** : Next.js 16 (App Router), React 19, TypeScript 5.9 (strict mais `ignoreBuildErrors:true`), Tailwind 4, Radix UI, Zustand 5 (persist), react-hook-form 7 + Zod 4, axios 1.15, socket.io-client (installé, **jamais utilisé**), recharts 3, framer-motion 12, react-i18next (installé, **utilisé sur 2 pages seulement**), lucide-react.

**Mobile** : Flutter Dart 3.10, flutter_bloc 9, dio 5, go_router 17, isar 3 (offline), flutter_secure_storage 10, geolocator 14, flutter_map 8, image_picker, flutter_tts, speech_to_text.

**AI service** : Flask 3.1, TensorFlow 2.18, NumPy 1.26, Pillow 11, gunicorn 23 (en dépendance, **non branché**).

**IoT service** : Node.js, MQTT (broker public `test.mosquitto.org` par défaut).

**Infra** : Docker (Node 22-bookworm-slim base), docker-compose, nginx reverse-proxy, PM2 (`ecosystem.config.js`), GitHub Actions CI.

---

## 3. Workflows utilisateur — cartographie

Reconstitués à partir des routes Next, des contrôleurs backend et des features Flutter :

| # | Workflow | Pages frontend | API backend | Service tiers |
|---|----------|----------------|-------------|---------------|
| W1 | Inscription + OTP | `(auth)/register` | `/auth/register`, `/auth/verify-otp` | Twilio SMS |
| W2 | Login + refresh + logout | `(auth)/login` | `/auth/login`, `/auth/refresh`, `/auth/logout` | — |
| W3 | Récupération mot de passe | `(auth)/forgot-password` | `/auth/forgot-password`, `/auth/reset-password` | SMTP |
| W4 | Mode visiteur (demo) | `app/demo` | session locale (sessionStorage) | — |
| W5 | Tableau de bord | `(dashboard)/dashboard` | `/dashboard/stats`, `/parcelles`, `/alertes` | — |
| W6 | Gestion parcelles | `(dashboard)/parcelles/{*}` | `/parcelles` (CRUD) | géolocalisation navigateur |
| W7 | Capteurs IoT + mesures | `(dashboard)/capteurs` | `/capteurs`, `/mesures` | MQTT broker, Socket.IO (non branché) |
| W8 | Alertes | `(dashboard)/alertes` | `/alertes`, `/alertes/{id}/process` | — |
| W9 | Recommandations IA | `(dashboard)/recommandations` | `/recommandations`, `/recommandations/{id}/apply` | AI service |
| W10 | Diagnostic image (maladies) | `(dashboard)/diagnostics` | `/diagnostics/image` | AI service |
| W11 | Marketplace | `(dashboard)/marketplace/{*}` | `/marketplace/produits`, `/commandes`, `/favorites` | — |
| W12 | Formations | `(dashboard)/formations/{*}` | `/formations`, `/formations/{id}/progress` | — |
| W13 | Calendrier agricole | `(dashboard)/calendrier` | `/calendrier`, `/calendrier/{id}/terminer` | — |
| W14 | Messages & communauté | `(dashboard)/messages`, `/communaute` | `/messages`, `/messages/conversations` | Socket.IO |
| W15 | Météo | composant header | `/weather` | API météo externe |
| W16 | Mobile : sync offline | écran offline | Isar local + sync delta | — |

Chaque workflow est ré-audité §4 à §8 avec les bugs précis détectés.

---

## 4. Audit Backend

### 4.1 Architecture et middlewares

**Point d'entrée** : `backend/src/server.js` ; ordre des middlewares :
1. helmet → 2. CORS → 3. rate-limit global → 4. auth rate-limit → 5. Socket.IO → 6. compression → 7. cookieParser → 8. securityMiddleware (custom) → 9. parsers JSON / urlencoded → 10. static `/uploads` → 11. errorHandler.

**Constats :**
- Architecture propre : `routes/`, `controllers/`, `services/`, `middlewares/`, `validators/`, `utils/`.
- Swagger exposé sur `/api/docs`.
- Worker `sensorWorker.js` présent mais **non démarré**.

### 4.2 Authentification & autorisation

- JWT HS256, access 1 h, refresh 30 j, hashés (SHA-256) en base avant stockage.
- Cookies HttpOnly + Secure + SameSite=strict ✅.
- Bcrypt rounds=12 ✅.
- Brute-force protection custom 5 tentatives / 15 min, blocage 30 min — **stockage mémoire**.
- Twilio OTP 6 chiffres, expire 10 min, 3 tentatives — **désactivé par défaut** : utilisateurs créés en `ACTIF` immédiatement.

**Bugs détectés :**
- **B-C1** [`backend/src/server.js:79-85`] CORS — fallback localhost si whitelist vide, même en prod si `ALLOW_LOCALHOST_CORS=true`. **CRITIQUE.**
- **B-C3** [`backend/src/middlewares/security.js:21`] brute-force in-memory ; reset au redémarrage. **CRITIQUE.**
- **B-C8** [`backend/src/server.js:157`] `cookieParser()` sans secret — cookies signés non sécurisés. **ÉLEVÉE.**
- **B-C9** [`backend/src/server.js:11,50`] `hpp` importé jamais branché. **MOYENNE.**
- **B-C11** [`backend/src/services/authService.js:61-64`] OTP non obligatoire — comptes créés ACTIF sans vérification téléphone. **ÉLEVÉE.**
- **B-S1** [`backend/src/config/index.js:41-42`] fallback `dev-only-secret-not-for-production` si `JWT_SECRET` vide en non-prod. **MOYENNE.**

### 4.3 Validation, injection, XSS

- `express-validator` utilisé sur toutes les routes auth.
- Sanitization custom récursive : strip `<script>`, `javascript:`, event handlers — **trop globale**, risque de perte de données légitimes.
- Aucun `$queryRaw` / `$executeRaw` dangereux ; les seuls usages (`SELECT 1` dans health check) sont sûrs.
- Multer : destinations hardcodées, pas de path traversal possible.

**Bugs détectés :**
- **B-V1** sanitization globale supprime des caractères valides (ex : `@` dans certains contextes). **FAIBLE.**
- **B-V2** schémas de validation non exhaustifs — auditer chaque route. **MOYENNE.**

### 4.4 Uploads

| Endpoint | Taille max | Filtre |
|----------|-----------|--------|
| `/auth/me` photo profil | 5 MB | `image/*` ✅ |
| `/upload/formation_video` | 50 MB | mp4, avi, mov ✅ |
| `/upload/diagnostic_image`, `/chat_image` | 50 MB | jpg, jpeg, png ✅ |
| `/upload/formation_document` | 50 MB | **AUCUN filtre** ❌ |

**Bugs détectés :**
- **B-C10** [`backend/src/routes/upload.js:40-46`] `formation_document` accepte tous les fichiers. **ÉLEVÉE** — risque d'upload `.php`, `.sh`, `.html`.
- **B-U1** [`backend/src/routes/upload.js:30`] `path.extname(file.originalname)` : extension venant de l'utilisateur, manipulation `.jpg.php` possible. **MOYENNE.**
- **B-U2** Sharp non utilisé alors qu'il est en dépendance — pas de redimensionnement, pas de re-encoding pour neutraliser les payloads. **MOYENNE.**
- **B-U3** Pas de scan antivirus. **FAIBLE.**

### 4.5 Headers & sécurité réseau

- helmet par défaut + CSP en prod ✅.
- `X-Frame-Options: DENY`, `Permissions-Policy` (geo, micro, camera, payment), `Cache-Control: no-store` sur `/auth` ✅.

**Bugs détectés :**
- **B-CSRF** Aucune protection CSRF (pas de token, pas de double-submit cookie). Mitigation partielle : SameSite=strict. **CRITIQUE.**
- **B-CSP1** CSP désactivée en non-prod — perd de la défense en dev. **MOYENNE.**

### 4.6 Rate-limit

| Limiteur | Limite |
|----------|--------|
| `loginLimiter` | 10 / 15 min / IP |
| `registerLimiter` | 5 / h / IP |
| `otpLimiter` | 5 / 10 min / (IP+phone) |
| `apiLimiter` global | **2000 / min / IP** (très permissif) |

**Bugs détectés :**
- **B-C5** [`backend/src/middlewares/rateLimiter.js:26`, `.env.example:52`] limit global 2000 req/min + store mémoire (donc inefficace en cluster). **CRITIQUE.**
- **B-RL1** `/health`, `/readiness` non protégés — possibilité de spam. **FAIBLE.**

### 4.7 Performances

- Pagination présente mais **sans plafond** : `?limit=99999999` accepté.
- `include` Prisma profonds dans certains contrôleurs — N+1 latents.
- Compression gzip activée ✅.
- Aucun cache Redis / ETag / `Cache-Control` sur GETs.
- `sensorWorker.js` non activé.

**Bugs détectés :**
- **B-C6** [`backend/src/controllers/parcellesController.js:17`] pagination sans `Math.min` → DoS mémoire. **CRITIQUE.**
- **B-P1** Absence de Redis pour cache + sessions + queue. **ÉLEVÉE** (plutôt optimisation).
- **B-P2** Pas d'ETag/304 sur les listings publics. **MOYENNE.**

### 4.8 Erreurs, logs, tests

- `errorHandler` central avec mapping Prisma (P2002, P2003, P2025) ✅.
- Stack masquée en prod ✅.
- Winston JSON + rotation daily ✅.
- **PII potentiellement loggée** (emails, téléphones, IPs).
- **Aucun test unitaire** (`*.test.js`/`*.spec.js` introuvable).

**Bugs détectés :**
- **B-C7** Couverture tests = 0 %. **CRITIQUE.**
- **B-L1** PII non masquée dans logs. **MOYENNE.**
- **B-L2** [`backend/src/server.js:276`] `unhandledRejection` loggé mais pas exit → fuites mémoire potentielles. **FAIBLE.**

### 4.9 Base de données (Prisma)

- 1 000+ lignes, ~40 modèles, ~100 index, relations bien définies.
- `Decimal` pour prix ✅, enums pour statuts ✅.
- `onDelete: Cascade` partout — **pas de soft delete**.
- Pas de table `AuditLog`.
- Pas de partitioning sur `Mesure` (table à très forte croissance).

---

## 5. Audit Frontend

### 5.1 Architecture

App Router avec groupes `(auth)`, `(dashboard)`, `(admin)`. Middleware `middleware.ts` protège les routes via cookies. Architecture propre.

**Bugs détectés :**
- **F-C1** [`frontend/next.config.mjs`] aucun header CSP / HSTS / X-Frame configuré. **CRITIQUE.**
- **F-C3** Aucun `app/error.tsx` ni `app/not-found.tsx` global — pages crash sans fallback. **CRITIQUE.**
- **F-C4** [`frontend/next.config.mjs:17`] `typescript.ignoreBuildErrors: true` masque les erreurs de build. **ÉLEVÉE.**
- **F-A1** Middleware se base uniquement sur cookies — pas de fallback header `Authorization`. **MOYENNE.**

### 5.2 Auth client & session

- Tokens en cookies HttpOnly (envoyés via `withCredentials:true`).
- Zustand persiste l'utilisateur dans `localStorage` (pas le token — OK).
- Logout : `localStorage.removeItem('auth-storage')` + appel backend.

**Bugs détectés :**
- **F-C6** [`frontend/src/lib/api.ts:62-96`] sur 401 expiré, `window.location.href='/login'` sans appel `useAuthStore.getState().logout()` → fuite contexte utilisateur. **CRITIQUE.**

### 5.3 Sécurité côté client

- Aucun `dangerouslySetInnerHTML` ✅.
- Logger `lib/logger.ts` muet en prod ✅.
- `NEXT_PUBLIC_*` ne contient que des URLs (pas de secrets) ✅.

**Bugs détectés :**
- **F-C7** [`frontend/src/app/(dashboard)/formations/[id]/page.tsx:214-220`] `target="_blank"` sans `rel="noopener noreferrer"`. **ÉLEVÉE.**

### 5.4 Workflows par parcours

#### W1/W2 Auth (login, register)
- Validation Zod cohérente ✅.
- Mot de passe complexe (maj/min/chiffre/symbole) ✅.
- **F-AUTH1** pas de limite OTP côté frontend (compté seulement backend) — message d'erreur peu explicite. **MOYENNE.**

#### W5 Dashboard
- 4+ fetchs séquentiels dans `useEffect`.
- **F-C8** [`frontend/src/app/(dashboard)/dashboard/page.tsx:87-115`] absence de `Promise.all` — waterfall réseau. **ÉLEVÉE.**

#### W6 Parcelles
- **F-UX1** Pas de confirmation avant suppression. **MOYENNE.**

#### W7 Capteurs IoT (temps réel)
- **F-C2** [`package.json`] `socket.io-client` installé mais **aucun import dans le code** → temps réel non fonctionnel. **CRITIQUE.**
- Polling implicite via re-render React → obsolète.

#### W8 Alertes
- 3 niveaux (info, important, critique).
- **F-UX2** Pas de notification native (Notifications API / son) pour `CRITIQUE`. **MOYENNE.**

#### W11 Marketplace
- **F-UX3** Pas de panier persistant — la commande est créée directement. **MOYENNE.**

#### W12 Formations
- **F-C7** liens externes `target="_blank"` sans `rel`. **ÉLEVÉE.**

#### W4 Mode visiteur
- Utilise `sessionStorage` (bonne pratique).
- **F-UX4** Pas d'expiration de session démo. **FAIBLE.**

### 5.5 Performance

- **74 % des composants en `'use client'`** — bundle alourdi, hydration risquée.
- `framer-motion` (1.2 MB) chargé pour animations mineures.
- `recharts` (500 KB) chargé globalement.
- Pas de `dynamic(import())` pour les libs lourdes.
- Zustand sans selectors — full state re-render.
- `next/image` partiel ; pas toujours `loading="lazy"`.

### 5.6 i18n

- `react-i18next` installé mais utilisé sur **2 fichiers seulement** (`parcelles/[id]`, `recommandations`).
- 99 % des strings hardcodées en français.
- **F-C5** non scalable multilingue (alors que langues locales — Baoulé, Malinké, Sénoufo — sont déclarées dans Zustand). **CRITIQUE.**

### 5.7 Erreurs et fallbacks

- `ErrorBoundary` existe mais **jamais wrappé** dans les layouts.
- Pas de retry réseau (sauf 401 → refresh token).
- Toasts via `react-hot-toast` ✅.

### 5.8 Accessibilité

- Composants Radix → ARIA defaults OK.
- Manques : skip-to-content, focus rings cohérents, `alt` systématique sur images produit.

---

## 6. Audit Mobile

### 6.1 Architecture

Architecture Clean Bloc-Cubit + repositories ; offline via Isar ; secure storage via flutter_secure_storage ; routing go_router.

### 6.2 Sécurité

- **M-C1** [`mobile/lib/core/config/environment_config.dart:134-138`] certificate pinning configuré avec **fingerprints placeholders** non validés. **ÉLEVÉE.**
- **M-C2** [`mobile/lib/core/config/environment_config.dart:62`] HTTP autorisé en dev (cleartext) — `network_security_config` Android probablement permissif. **ÉLEVÉE.**
- **M-C3** [`mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart:54-57`] tokens loggés en debug. **ÉLEVÉE.**
- **M-C4** [`mobile/lib/core/config/environment_config.dart:105-125`] timeouts Dio incohérents (10 s prod / 30 s dev) — risquent le timeout en réseau rural Côte d'Ivoire. **MOYENNE.**

### 6.3 UX

- **M-UX1** Pas de fallback pour permissions GPS/caméra refusées.
- **M-UX2** Pas d'indicateur "Hors-ligne" persistant.

---

## 7. Audit AI Service

### 7.1 Sécurité critique

- **A-C1** [`ai_service/app.py:240`] **Flask `app.run()` lancé en production** — serveur de développement, mono-thread, pas de sécurité. **CRITIQUE.**
- **A-C2** Aucune authentification entre le backend et l'AI service — n'importe qui sur le réseau peut requêter `/predict`. **CRITIQUE.**
- **A-C3** CORS Flask par défaut `*`. **ÉLEVÉE.**
- **A-C4** [`ai_service/app.py:40,165`] `MAX_IMAGE_SIZE=10MB` mais aucune validation des dimensions / profondeur / magic bytes après décodage. **ÉLEVÉE.**
- **A-C5** [`ai_service/app.py:55-79`] TensorFlow chargé en *fail-soft* — service répond `200 OK` même quand le modèle n'est pas chargé. **ÉLEVÉE.**

### 7.2 Performance

- Modèle TF probablement rechargé par requête.
- Pas de quantization (TFLite).
- Pas de cache résultats.

---

## 8. Audit IoT Service

### 8.1 Sécurité critique

- **I-C1** [`iot_service/index.js:41`] broker public `test.mosquitto.org` par défaut — fuite de toutes les mesures sur internet. **CRITIQUE.**
- **I-C2** [`iot_service/index.js:45-50`] credentials MQTT optionnels — déploiement sans auth possible. **ÉLEVÉE.**
- **I-C3** [`iot_service/index.js:85,106-108`] aucune validation de schéma sur payloads MQTT. **ÉLEVÉE.**
- **I-C4** [`iot_service/index.js:82`] device ID extrait du topic, pas signé HMAC — usurpation triviale. **ÉLEVÉE.**
- **I-C5** Aucun rate-limit message/device — flood attack possible. **MOYENNE.**

---

## 9. Audit Infrastructure

### 9.1 Docker / docker-compose

- **D-C1** [`docker-compose.yml:51-52`] secrets DB en clair. **ÉLEVÉE.**
- **D-D1** [`Dockerfile:3,21,43,49,67`] base `node:22-bookworm-slim` sans scan de vulnérabilités CI. **ÉLEVÉE.**
- **D-D2** Restart policies `unless-stopped` → cache les crashs. **MOYENNE.**
- **D-D3** Pas de quotas disque sur `uploads`/`logs` volumes. **FAIBLE.**

### 9.2 nginx

- **D-N1** [`backend/nginx.conf:77-81`] CSP header absent. **MOYENNE.**
- **D-N2** [`backend/nginx.conf:104-105`] rate-limit auth très strict 5 req/min — risque faux positif. **FAIBLE.**

### 9.3 PM2 (`ecosystem.config.js`)

- Mode fork (pas cluster) ; pas de `max_memory_restart`.
- Logs non rotés via pm2-logrotate.

### 9.4 CI/CD GitHub Actions

- **D-C3** [`.github/workflows/ci.yml:37`] audit deps non bloquant (`|| true`). **MOYENNE.**
- **D-C4** [`.github/workflows/ci.yml:147-150`] credentials DB de test hardcodés. **MOYENNE.**
- Pas de SAST (CodeQL), pas de scan d'image (Trivy), pas de gitleaks.

### 9.5 `.env.example`

- **D-C2** [`.env.example:38-39`] secrets exemple courts (28 caractères). **ÉLEVÉE.**
- Documente la liste complète des secrets — donne carte à un attaquant ; acceptable pour un MVP, à durcir.

### 9.6 Observabilité

- **D-C5** Aucun APM (Sentry, Datadog), pas de log aggregation, pas de métriques Prometheus.
- Healthchecks `/health` et `/readiness` existent mais ne distinguent pas DB+Redis+AI.

---

## 10. Top 10 risques bloquants

| # | ID | Description | Impact | Sévérité |
|---|----|-------------|--------|----------|
| 1 | A-C1 | Flask `app.run()` en prod | Crash, mono-thread, pas de TLS | CRITIQUE |
| 2 | B-C5 + B-C3 | Rate-limit & brute-force in-memory + global 2000 req/min | DoS, brute-force réussie après restart | CRITIQUE |
| 3 | B-CSRF | Aucune protection CSRF | Account takeover via CSRF | CRITIQUE |
| 4 | I-C1 + I-C3 | Broker MQTT public + payloads non validés | Fuite données, injection | CRITIQUE |
| 5 | B-C6 | Pagination sans plafond | DoS mémoire | CRITIQUE |
| 6 | B-C10 | Upload `formation_document` sans filtre | RCE potentielle | CRITIQUE |
| 7 | A-C2 | Pas d'auth entre backend ↔ AI service | Lecture/écriture libre | CRITIQUE |
| 8 | F-C1 | Pas de CSP frontend | XSS amplifié | CRITIQUE |
| 9 | B-C2 | `ALLOW_DEMO_START` permet boot sans DB | États incohérents en prod | CRITIQUE |
| 10 | B-C7 | 0 % de tests automatisés | Régressions silencieuses | CRITIQUE |

---

## 11. Plan de correction des bugs

### Phase 1 — Hotfix sécurité (J+1 → J+5) — bloque la mise en prod

| # | Action | Fichiers | Effort |
|---|--------|----------|--------|
| 1 | Brancher `app.use(hpp())` après les parsers JSON | `backend/src/server.js` | 5 min |
| 2 | `cookieParser(process.env.COOKIE_SECRET)` + ajouter `COOKIE_SECRET` dans `.env.example` et validation prod | `backend/src/server.js`, `.env.example`, `backend/src/config/index.js` | 15 min |
| 3 | Supprimer fallback CORS localhost en prod (erreur si whitelist vide & `NODE_ENV=production`) | `backend/src/server.js:65-104` | 20 min |
| 4 | Conditionner `ALLOW_DEMO_START` strictement à `NODE_ENV !== 'production'` (idéalement supprimer) | `backend/src/server.js:239` | 15 min |
| 5 | `JWT_SECRET` ≥ 64 chars, exit-1 si manquant en *toute* env | `backend/src/config/index.js:41-42, 141-184` | 15 min |
| 6 | Plafond pagination : `Math.min(parseInt(limit) || 20, 100)` dans tous les contrôleurs liste | `backend/src/controllers/*.js` | 1 h |
| 7 | OTP obligatoire — statut initial `EN_ATTENTE`, vérification requise pour activer | `backend/src/services/authService.js:61-64` | 1 h |
| 8 | Whitelist MIME stricte sur `formation_document` (pdf, docx) | `backend/src/routes/upload.js:40-46` | 30 min |
| 9 | Migrer Flask vers gunicorn — `gunicorn -w 2 -b 0.0.0.0:5000 app:app` | `ai_service/app.py:240`, `Dockerfile`, `docker-compose.yml` | 30 min |
| 10 | Auth shared-secret backend ↔ AI (`X-Internal-Token`) + vérification middleware | `ai_service/app.py`, `backend/src/services/aiService.js` | 1 h |
| 11 | Brancher Flask-CORS restrictif (whitelist origines backend) | `ai_service/app.py` | 15 min |
| 12 | Désactiver broker MQTT public par défaut, exiger creds en prod | `iot_service/index.js:41-50` | 30 min |
| 13 | Validation schéma payload MQTT (Joi/zod) | `iot_service/index.js:85-108` | 2 h |
| 14 | Rate-limit message/device IoT (token bucket par device-id) | `iot_service/index.js` | 2 h |
| 15 | Headers CSP/HSTS/X-Frame dans `next.config.mjs` (`async headers()`) | `frontend/next.config.mjs` | 30 min |
| 16 | Désactiver `ignoreBuildErrors` + corriger erreurs TS bloquantes | `frontend/next.config.mjs:17` + multiples | 2-4 h |
| 17 | `rel="noopener noreferrer"` sur tous les liens externes | `frontend/src/app/(dashboard)/formations/[id]/page.tsx:214-220` + grep `target="_blank"` | 30 min |
| 18 | Dio interceptor : redaction des champs `accessToken`, `refreshToken`, `password`, `otp` dans logs | `mobile/lib/core/network/dio_client.dart`, `mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart:54-57` | 1 h |
| 19 | Forcer HTTPS en mobile dev + `cleartextTrafficPermitted=false` | `mobile/lib/core/config/environment_config.dart:62`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` | 1 h |
| 20 | Sortir secrets de `docker-compose.yml` vers Docker secrets / `.env` non commité | `docker-compose.yml:51-52`, `.env.example` | 1 h |

**Critères d'acceptation Phase 1 :** `npm run test:security` + smoke e2e + scan Trivy passent sans CRITIQUE.

### Phase 2 — Hardening sécurité (J+6 → J+15)

| # | Action | Fichiers / cible |
|---|--------|------------------|
| 21 | CSRF protection (double-submit cookie) sur `/api/v1/*` mutations | `backend/src/middlewares/csrf.js` (nouveau) |
| 22 | Migrer rate-limit + brute-force vers Redis (`rate-limit-redis`, `ioredis`) | `backend/src/middlewares/rateLimiter.js`, `security.js` |
| 23 | Réduire rate-limit global à 100-300 req/min, durcir auth limiter | `.env.example`, `backend/src/config/index.js:99` |
| 24 | Refresh tokens : rotation stricte + invalidation chaîne sur réutilisation détectée (`replacedBy` field) | `backend/src/middlewares/auth.js:314-363`, `backend/prisma/schema.prisma` |
| 25 | Audit trail (`AuditLog` model : userId, action, entityType, entityId, before/after JSON) + middleware | `backend/prisma/schema.prisma`, `backend/src/middlewares/audit.js` |
| 26 | RBAC : audit ligne par ligne ownership (ex `parcelle.userId === req.user.id`) sur tous les contrôleurs | `backend/src/controllers/*` |
| 27 | Magic-byte validation sur uploads (`file-type` package) en plus du MIME | `backend/src/routes/upload.js`, `backend/src/middlewares/upload.js` |
| 28 | Antivirus uploads : ClamAV en side-car docker-compose | `docker-compose.yml`, `backend/src/services/clamavService.js` |
| 29 | Certificate pinning Flutter avec vrais fingerprints (script `scripts/generate_pins.sh`) | `mobile/lib/core/config/environment_config.dart:134-138` |
| 30 | Frontend : purger Zustand + flush sockets avant redirection 401 | `frontend/src/lib/api.ts:62-96` |
| 31 | PII redaction dans logger backend (winston format custom : email/phone/IP partial mask) | `backend/src/utils/logger.js` |
| 32 | CodeQL + Trivy + Snyk dans CI (bloquant `moderate+`) | `.github/workflows/security.yml` (nouveau) |
| 33 | gitleaks pre-commit + CI | `.github/workflows/ci.yml`, `.pre-commit-config.yaml` |

### Phase 3 — Tests & qualité (J+10 → J+25)

| # | Action |
|---|--------|
| 34 | Setup Jest + supertest (backend), cible **80 %** sur auth/payment/parcelles/uploads |
| 35 | Tests unitaires Flutter (`flutter_test` déjà disponible) — repositories, blocs |
| 36 | Tests Vitest/Jest frontend — composants critiques (Login, Dashboard, ProtectedRoute) |
| 37 | Tests pytest pour AI service (mock TensorFlow, validation endpoints) |
| 38 | Tests Playwright e2e couvrant : signup→OTP→login→créer parcelle→ajouter capteur→voir mesure |
| 39 | Intégrer ces suites dans CI bloquant (job `tests`) |
| 40 | OWASP ZAP nightly scan en CI scheduled |

---

## 12. Plan d'optimisation performance

### 12.1 Backend
- **P-B1** Activer **Redis** : sessions, cache parcelles/produits/mesures aggregées, rate-limit, brute-force, lock distribué. Gain attendu : −40 % latence p95.
- **P-B2** **ETag/304** sur GETs idempotents (parcelles, produits, formations, météo).
- **P-B3** `Cache-Control: public, max-age=300, stale-while-revalidate=60` sur ressources publiques.
- **P-B4** Activer `sensorWorker.js` [`backend/src/server.js:219-224`] — traitement asynchrone des mesures IoT.
- **P-B5** Audit Prisma : remplacer `include` profonds par `select` ciblés sur les listings.
- **P-B6** Partitionnement temporel sur `Mesure` (par mois) — table partitionnée MySQL ou rotation logique.
- **P-B7** Index manquants à valider : `Mesure(capteurId, timestamp DESC)`, `Alerte(userId, createdAt DESC, status)`, `Commande(userId, status, createdAt)`.
- **P-B8** Queue **BullMQ + Redis** : envois emails/SMS, génération PDF, traitement IA.
- **P-B9** Pipeline Sharp upload image → thumb/md/full + WebP.
- **P-B10** Brotli en plus de gzip via nginx.

### 12.2 Frontend
- **P-F1** Implémenter Socket.IO (alertes, mesures live) ou supprimer la dépendance morte.
- **P-F2** Convertir composants `'use client'` → Server Components (cible ≤ 40 % client) — pages liste (formations, marketplace) en priorité.
- **P-F3** `dynamic(import())` sur recharts, framer-motion, react-i18next setup. Gain estimé : −200 KB bundle initial.
- **P-F4** `Promise.all` sur les fetchs dashboard.
- **P-F5** Zustand selectors (`useAuthStore(s => s.user)`) pour éviter re-renders globaux.
- **P-F6** `next/image` partout + `loading="lazy"` + tailles explicites + whitelist hosts complète.
- **P-F7** Activer `experimental.optimizePackageImports` pour `lucide-react`, `date-fns`, `recharts`.
- **P-F8** PWA / Service Worker offline (`next-pwa`) — utile en zone rurale CI.

### 12.3 Mobile
- **P-M1** Cache offline Isar avec TTL : parcelles 24 h, mesures 5 min, météo 1 h.
- **P-M2** Compression images avant upload (`flutter_image_compress`).
- **P-M3** Préchargement météo + alertes au démarrage en parallèle au splash.
- **P-M4** Lazy loading des écrans via go_router redirects.

### 12.4 AI service
- **P-A1** Gunicorn `--workers $(nproc*2+1) --threads 2 --worker-class gthread --timeout 120`.
- **P-A2** Modèle TF chargé en module-level singleton.
- **P-A3** Quantization TFLite (`tf.lite.TFLiteConverter`) — taille ÷4, latence ÷2.
- **P-A4** Cache résultats par hash image (Redis SHA-256 → résultat).

### 12.5 IoT
- **P-I1** Backpressure : si backend lent, queue MQTT en local au lieu de drop.
- **P-I2** Batch insert mesures (toutes les 5 s ou 100 mesures).

### 12.6 Base de données
- **P-D1** Pool Prisma : `connection_limit` adapté ; `relationMode = "foreignKeys"` si MySQL ≥ 8.
- **P-D2** Read replica MySQL pour les listings → routing Prisma middleware.
- **P-D3** Archivage `Mesure` > 1 an vers `mesures_archive`.

### 12.7 Infra
- **P-X1** PM2 cluster mode (`exec_mode:'cluster', instances:'max'`) dans `ecosystem.config.js`.
- **P-X2** nginx : `gzip_static`, `brotli`, `keepalive_timeout 65`, cache statique 30 j.
- **P-X3** CDN (Cloudflare) devant nginx pour `_next/static`, `/uploads`.

---

## 13. Plan UX

| # | Amélioration |
|---|--------------|
| UX-1 | Loading states explicites (skeleton + spinner labellé par section) sur le dashboard. |
| UX-2 | `AlertDialog` confirmation avant `delete()` sur parcelles, produits, comptes. |
| UX-3 | Panier persistant (Zustand persist) avant création de commande marketplace. |
| UX-4 | Notifications natives (Web Push API + Notifications API mobile) pour alertes CRITIQUE. |
| UX-5 | `app/error.tsx` + `app/not-found.tsx` avec illustration et bouton retour. |
| UX-6 | Mode hors-ligne explicite : badge "Hors-ligne" + retry auto. |
| UX-7 | Retry exponentiel axios sur 5xx/timeouts (3 tentatives, backoff 1 s/2 s/4 s). |
| UX-8 | i18n complet : extraction des strings, fichiers `fr.json`, `en.json`, `bci.json` (Baoulé), `mxx.json` (Malinké), `sef.json` (Sénoufo). |
| UX-9 | Skip-to-content + focus rings tailwind cohérents (a11y). |
| UX-10 | Géolocalisation : fallback saisie manuelle si GPS refusé, message clair. |

---

## 14. Plan DevOps & observabilité

| # | Action |
|---|--------|
| OPS-1 | Sentry (backend + frontend + mobile) — DSN par environnement. |
| OPS-2 | Log aggregation : Loki + Grafana (ou Datadog). |
| OPS-3 | Métriques Prometheus côté backend (`prom-client`) : RPS, latence, erreurs, queue size. |
| OPS-4 | Dashboard Grafana : RED metrics + KPIs business (signups, mesures/jour). |
| OPS-5 | Alerting (PagerDuty / Discord webhook) si 5xx > 1 % ou DB down. |
| OPS-6 | Backup MySQL daily (`mysqldump` → S3) + test restore mensuel. |
| OPS-7 | Blue-green deploy via 2 services PM2 + switch upstream nginx. |
| OPS-8 | Runbook incident `docs/RUNBOOK.md` : DB full, AI down, MQTT broker down. |
| OPS-9 | Trivy + grype dans CI sur images Docker (bloquant CRITICAL). |
| OPS-10 | OWASP ZAP scheduled nightly. |
| OPS-11 | Rotation JWT secret (cron mensuel + grace period 1 h en double-validation). |
| OPS-12 | Healthchecks `/readiness` distinct de `/liveness` (vérifie DB + Redis + AI). |

---

## 15. Procédure de test & critères d'acceptation

### 15.1 Smoke local
```bash
npm run install:all
npm run dev               # backend 3000, frontend 3603, IoT, AI 5000
# scripts existants
cd backend && npm run test:security
cd backend && npm run test:prod-validation
cd backend && npm run test:platform-validation
bash TEST_VISITOR_MODE.sh
```

### 15.2 Parcours e2e manuels (à automatiser Phase 3)
1. Signup → OTP → Login → Dashboard.
2. Créer parcelle → assigner capteur → ingestion mesure simulée → voir alerte.
3. Marketplace : lister produits → ajouter favori → créer commande.
4. Diagnostic IA : upload image → voir résultat → noter recommandation.
5. Mode visiteur (demo) : tour guidé sans auth.

### 15.3 Critères d'acceptation finale
- Trivy + `npm audit` + `flutter pub outdated` sans CRITIQUE/HIGH non documenté.
- `npm run test:security` ✅
- ZAP baseline scan ✅
- Couverture tests : ≥ 70 % backend, ≥ 50 % frontend.
- Lighthouse mobile/desktop ≥ 85 sur dashboard.
- Load test k6 : 500 RPS soutenus sans 5xx pendant 10 min.

---

## 16. Roadmap consolidée 12 semaines

```
S1   ████          Phase 1 hotfix sécurité (B-C* + F-C* + A-C* + I-C* + D-C*)
S2   ████          Phase 1 fin + démarrage Phase 2
S3-4 ████████      Phase 2 hardening (CSRF, Redis, audit trail, RBAC review)
S5-6 ████████      Phase 3 tests (Jest + Playwright + pytest, CI bloquant)
S7-8 ████████      Optim perf backend (Redis cache, worker, queue, indexes)
S9   ████          Optim perf frontend (Server Components, lazy, Promise.all, PWA)
S10  ████          Optim mobile + i18n complet (FR/EN/BCI/MXX/SEF)
S11  ████          DevOps (Sentry, Grafana, blue-green, backups)
S12  ████          Recette finale + scan ZAP + load test (k6)
```

---

## 17. Référence rapide — fichiers à modifier

### Backend
- [`backend/src/server.js`](backend/src/server.js) — middlewares, CORS, hpp, cookieParser, démo flag.
- [`backend/src/config/index.js`](backend/src/config/index.js) — secrets validation, JWT length.
- [`backend/src/middlewares/rateLimiter.js`](backend/src/middlewares/rateLimiter.js) — Redis store.
- [`backend/src/middlewares/security.js`](backend/src/middlewares/security.js) — brute-force Redis.
- [`backend/src/middlewares/auth.js`](backend/src/middlewares/auth.js) — refresh rotation stricte.
- `backend/src/middlewares/csrf.js` *(nouveau)* — double-submit cookie.
- `backend/src/middlewares/audit.js` *(nouveau)* — hook AuditLog.
- [`backend/src/controllers/`](backend/src/controllers/) — pagination plafond, ownership checks.
- [`backend/src/routes/upload.js`](backend/src/routes/upload.js) — MIME whitelist + magic bytes.
- [`backend/src/services/authService.js`](backend/src/services/authService.js) — OTP forcé.
- [`backend/prisma/schema.prisma`](backend/prisma/schema.prisma) — index, AuditLog, partitioning Mesure.
- [`backend/src/utils/logger.js`](backend/src/utils/logger.js) — redaction PII.

### Frontend
- [`frontend/next.config.mjs`](frontend/next.config.mjs) — CSP/HSTS, `ignoreBuildErrors:false`, `headers()`.
- [`frontend/src/lib/api.ts`](frontend/src/lib/api.ts) — purge store on 401, retry 5xx.
- [`frontend/src/lib/store.ts`](frontend/src/lib/store.ts) — selectors.
- `frontend/src/app/error.tsx`, `frontend/src/app/not-found.tsx` *(à créer)*.
- `frontend/src/lib/socket.ts` *(à créer ou supprimer la dépendance)*.
- [`frontend/src/app/(dashboard)/dashboard/page.tsx`](frontend/src/app/(dashboard)/dashboard/page.tsx) — `Promise.all`.
- [`frontend/src/app/(dashboard)/formations/[id]/page.tsx`](<frontend/src/app/(dashboard)/formations/[id]/page.tsx>) — `rel="noopener noreferrer"`.
- `frontend/src/i18n/` *(à compléter — fr/en/bci/mxx/sef)*.

### Mobile
- [`mobile/lib/core/config/environment_config.dart`](mobile/lib/core/config/environment_config.dart) — pinning, HTTPS, timeouts.
- [`mobile/lib/core/network/dio_client.dart`](mobile/lib/core/network/dio_client.dart) — redaction logs.
- [`mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart`](mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart) — redaction logs.

### AI service
- [`ai_service/app.py`](ai_service/app.py) — entrypoint gunicorn, header auth, Flask-CORS, validation image.
- `ai_service/Dockerfile` *(à créer)* — `CMD gunicorn ...`.

### IoT service
- [`iot_service/index.js`](iot_service/index.js) — broker prod-only, schema validation, rate-limit, HMAC.

### Infra
- [`docker-compose.yml`](docker-compose.yml) — secrets, healthchecks robustes, ClamAV side-car.
- [`nginx/`](nginx/) — CSP, gzip_static, brotli, cache.
- [`ecosystem.config.js`](ecosystem.config.js) — cluster mode, log rotate.
- [`.github/workflows/ci.yml`](.github/workflows/ci.yml) — audit bloquant, vault secrets, CodeQL/Trivy.
- [`.env.example`](.env.example) — secrets longs + `change_me_in_prod`.

---

## Annexes

### A. Inventaire des bugs par identifiant

```
B-C1..B-C11   Backend critiques (cf §4)
B-V1, B-V2    Backend validation
B-U1..B-U3    Backend uploads
B-CSP1, B-CSRF Backend headers / CSRF
B-RL1         Backend rate-limit
B-P1, B-P2    Backend performance
B-L1, B-L2    Backend logs
B-S1          Backend secrets

F-C1..F-C8    Frontend critiques (cf §5)
F-A1          Frontend auth middleware
F-AUTH1       Frontend OTP UX
F-UX1..F-UX4  Frontend UX

M-C1..M-C4    Mobile critiques (cf §6)
M-UX1, M-UX2  Mobile UX

A-C1..A-C5    AI service critiques (cf §7)

I-C1..I-C5    IoT service critiques (cf §8)

D-C1..D-C5    DevOps / infra critiques (cf §9)
D-D1..D-D3    Docker
D-N1, D-N2    nginx
```

### B. Commandes utiles à exécuter en début d'implémentation

```bash
# Backend — ajouter Redis
cd backend && npm install ioredis rate-limit-redis bullmq

# Backend — magic bytes
cd backend && npm install file-type@^19

# Frontend — extraction i18n
cd frontend && npx i18next-parser --output 'src/i18n/$LOCALE.json' 'src/**/*.{ts,tsx}'

# CI — gitleaks
gitleaks detect --source . --redact

# Scan d'image
docker run --rm -v "$PWD":/scan aquasec/trivy:latest fs /scan
```

### C. Évolution suggérée du schéma Prisma (extrait)

```prisma
model AuditLog {
  id          String   @id @default(uuid())
  userId      String?
  action      String   // CREATE / UPDATE / DELETE / LOGIN / LOGOUT / OTP_VERIFY ...
  entityType  String?  // "Parcelle", "Commande", ...
  entityId    String?
  diffJson    Json?
  ip          String?
  userAgent   String?
  createdAt   DateTime @default(now())

  @@index([userId, createdAt])
  @@index([entityType, entityId, createdAt])
}

model RefreshToken {
  // ... existant ...
  replacedBy  String?  // chaînage rotation — détecte la réutilisation
  @@index([replacedBy])
}
```

### D. Squelette `next.config.mjs` durci

```js
/** @type {import('next').NextConfig} */
const securityHeaders = [
  { key: 'Content-Security-Policy', value: "default-src 'self'; script-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' https://api.example.com wss://api.example.com" },
  { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=(self)' },
];

export default {
  reactStrictMode: true,
  typescript: { ignoreBuildErrors: false },
  experimental: { optimizePackageImports: ['lucide-react', 'date-fns', 'recharts'] },
  async headers() {
    return [{ source: '/(.*)', headers: securityHeaders }];
  },
};
```

---

**Document généré le 2026-05-06.**
**Version :** 1.0 — audit initial complet.
**Prochaine étape recommandée :** ouvrir 20 issues GitHub (Phase 1) avec labels `severity:critical|high`, `area:backend|frontend|mobile|ai|iot|devops`, puis démarrer les PRs hotfix dans l'ordre du tableau §11.
