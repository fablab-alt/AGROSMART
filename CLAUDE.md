# CLAUDE.md — AgroSmart CI

Référence complète du projet pour les sessions de développement. Travailler directement sur les fichiers locaux, pas de branches Git.

---

## Vue d'ensemble

**AgroSmart CI** est une plateforme agricole intelligente pour la Côte d'Ivoire intégrant IoT, IA et analyse prédictive pour optimiser la production agricole.

- **Domaine** : Agriculture intelligente (Smart Farming)
- **Cible** : Producteurs, agronomes, acheteurs, coopératives en Côte d'Ivoire
- **Langues UI** : Français, Baoulé, Malinké, Senoufo, Fulfulde, Bambara
- **Domain de prod** : `agrosmart.voisilab.online`
- **Taille** : ~1.1 GB, 554 fichiers sources
- **Licence** : MIT

---

## Architecture multi-services

```
Internet (HTTPS/SSL via Let's Encrypt)
    ↓
Traefik / Nginx (reverse proxy)
    ├─ agrosmart.voisilab.online          → Frontend Next.js   :3603
    ├─ api.agrosmart.voisilab.online      → Backend Node.js    :3600
    ├─ ai.agrosmart.voisilab.online       → AI Service Flask   :5001
    └─ iot.agrosmart.voisilab.online      → IoT Service MQTT   :4000
    ↓
PM2 (ou Docker Compose)
    ↓
MySQL 8.x (Hostinger VPS)
```

---

## Tech Stack

### Backend (`/backend/`)
| Composant | Technologie |
|-----------|-------------|
| Runtime | Node.js 22.x |
| Framework | Express 5.2.1 |
| ORM | Prisma 6.9.0 |
| Base de données | MySQL 8.x (Hostinger) |
| Real-time | Socket.IO 4.8.3 |
| Auth | JWT (jsonwebtoken 9.0.3) + bcryptjs 3.0.3 |
| Upload | Multer 2.0.2 |
| Image | Sharp 0.34.5 |
| Validation | express-validator 7.3.1 + Zod |
| Sécurité | Helmet 8.1.0, HPP 0.2.3, express-rate-limit |
| Logging | Winston 3.19.0, winston-daily-rotate-file |
| Email | Nodemailer |
| SMS/WhatsApp | Twilio SDK |
| Tâches planifiées | node-cron |
| Export | JSON2CSV |
| API Docs | Swagger/OpenAPI |
| Process | PM2 (cluster mode) |

### Frontend (`/frontend/`)
| Composant | Technologie |
|-----------|-------------|
| Framework | Next.js 16.2.1 (App Router) |
| React | 19.2.4 |
| Langage | TypeScript 5.9.3 |
| Styles | Tailwind CSS 4.1.18 |
| Composants UI | Radix UI |
| State | Zustand 5.0.11 |
| Formulaires | React Hook Form 7.71.1 + Zod 4.3.6 |
| HTTP | Axios 1.13.5 |
| Real-time | socket.io-client 4.8.3 |
| Charts | Recharts 3.7.0 |
| i18n | i18next 25.8.4 + react-i18next |
| Animations | Framer Motion 12.33.0 |
| Icônes | Lucide React 0.563.0 |
| Notifications | React Hot Toast 2.6.0 |
| Port | 3603 |

### Mobile (`/mobile/`)
| Composant | Technologie |
|-----------|-------------|
| Framework | Flutter 3.10+ / Dart 3.10.1+ |
| State | flutter_bloc 9.1.1 (BLoC/Cubit) |
| HTTP | Dio 5.4.0 |
| DB locale | Isar 3.1.0+1 |
| Routing | go_router 17.0.1 |
| DI | get_it 9.2.0 |
| Auth biométrique | local_auth 2.3.0 |
| Storage sécurisé | flutter_secure_storage 10.0.0 |
| Cartes | flutter_map 8.2.2 |
| Voice | flutter_tts 4.2.3 + speech_to_text 7.0.0 |
| QR | mobile_scanner 7.1.4 |
| Charts | fl_chart 1.1.1 |
| Push notifs | flutter_local_notifications 18.0.1 |
| Localisation | geolocator 14.0.1 |
| Plateformes | iOS, Android, Web, macOS, Windows, Linux |

### AI Service (`/ai_service/`)
| Composant | Technologie |
|-----------|-------------|
| Runtime | Python 3.11+ |
| Framework | Flask 3.1.1 |
| ML | TensorFlow 2.20.0 |
| Numérique | NumPy 1.26.4 |
| Images | Pillow 11.2.1 |
| Serveur prod | Gunicorn 23.0.0 (2 workers, port 5001) |

### IoT Service (`/iot_service/`)
| Composant | Technologie |
|-----------|-------------|
| Runtime | Node.js |
| Protocole | MQTT (mqtt 5.14.1) |
| Port HTTP | 4000 |
| Config broker | `/iot_service/config/mosquitto.conf` |

---

## Structure des répertoires

```
agrosmart C V/
├── backend/
│   ├── src/
│   │   ├── server.js              # Point d'entrée Express
│   │   ├── socket.js              # Config WebSocket
│   │   ├── worker.js              # Worker en arrière-plan
│   │   ├── config/                # loadEnv, database, logger, swagger, prisma, constants
│   │   ├── controllers/           # 35+ contrôleurs
│   │   ├── routes/                # 38 fichiers de routes
│   │   ├── services/              # 15 services métier
│   │   ├── middlewares/           # Auth, RBAC, validation, erreurs, rate limit
│   │   ├── validators/            # Schémas de validation
│   │   ├── workers/               # Jobs asynchrones
│   │   └── utils/                 # Helpers (logger, phone formatter, cache)
│   ├── prisma/
│   │   ├── schema.prisma          # Schéma BDD (1502 lignes)
│   │   └── migrations/
│   ├── scripts/                   # 26 scripts (seed, tests, audit sécu)
│   ├── entrypoint.prod.sh         # Script démarrage Docker (wait MySQL → migrate → seed → start)
│   ├── .env.example
│   └── package.json
│
├── frontend/
│   ├── src/
│   │   ├── app/
│   │   │   ├── page.tsx           # Landing page publique (boutons Mode démo ajoutés)
│   │   │   ├── layout.tsx
│   │   │   ├── (auth)/            # login, register, forgot-password
│   │   │   ├── (dashboard)/       # 26 pages protégées (+ bypass visiteur)
│   │   │   └── (admin)/           # 10+ pages admin
│   │   ├── components/
│   │   │   ├── ui/                # Composants Radix UI wrappés
│   │   │   ├── layout/            # Header, Sidebar, BottomNav
│   │   │   ├── landing/           # Sections landing page (Navbar, HeroSection, CTASection modifiés)
│   │   │   ├── providers/         # Context providers
│   │   │   ├── capteurs/          # Composants feature
│   │   │   └── visitor/
│   │   │       └── VisitorBanner.tsx  # Bannière amber sticky (mode démo)
│   │   ├── lib/
│   │   │   ├── api.ts             # Client Axios + intercepteurs (+ adaptateur mock visiteur)
│   │   │   ├── store.ts           # Stores Zustand (+ visitorMode, enableVisitorMode, disableVisitorMode)
│   │   │   ├── visitorActions.ts  # Helpers enterVisitorMode / exitVisitorMode
│   │   │   ├── mocks/             # Couche mock complète pour mode visiteur
│   │   │   │   ├── index.ts       # Dispatcher principal (50+ routes)
│   │   │   │   ├── helpers.ts     # daysAgo, hoursAgo, sineSeries, range
│   │   │   │   └── data/
│   │   │   │       ├── user.ts          # VISITOR_USER + VISITOR_TOKEN
│   │   │   │       ├── parcelles.ts     # 5 parcelles (OPTIMAL/SURVEILLANCE/CRITIQUE)
│   │   │   │       ├── capteurs.ts      # 12 capteurs + 3 stations IoT
│   │   │   │       ├── mesures.ts       # Séries 7j (42 pts/capteur, sine + bruit)
│   │   │   │       ├── alertes.ts       # 8 alertes (INFO/IMPORTANT/CRITIQUE)
│   │   │   │       ├── recommandations.ts # 5 recommandations IA
│   │   │   │       ├── meteo.ts         # Météo actuelle + prévisions 7j + historique 30j
│   │   │   │       ├── marketplace.ts   # 20 produits, 3 commandes, favoris
│   │   │   │       ├── formations.ts    # 12 formations (video/pdf/article)
│   │   │   │       ├── stocks.ts        # 15 articles + mouvements
│   │   │   │       ├── calendrier.ts    # 20 activités sur 60 jours
│   │   │   │       ├── fichesPratiques.ts # 10 fiches + catégories
│   │   │   │       ├── communaute.ts    # 15 posts, leaderboard, gamification
│   │   │   │       ├── messages.ts      # 4 conversations + messages
│   │   │   │       ├── performance.ts   # ROI, rendements, comparaison saisonnière
│   │   │   │       └── dashboard.ts     # Stats agrégées, KPIs, analytics
│   │   │   ├── utils.ts
│   │   │   ├── i18n.ts
│   │   │   └── logger.ts
│   │   └── hooks/                 # useErrorHandler et autres
│   ├── next.config.mjs            # output: 'standalone' activé (Docker)
│   └── public/                    # logo.png, favicon, grid.svg
│
├── mobile/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── injection_container.dart
│   │   ├── core/
│   │   │   ├── config/            # Environment config
│   │   │   ├── network/           # api_client.dart, network_info.dart
│   │   │   ├── services/          # 10+ services (encryption, location, voice, chatbot...)
│   │   │   ├── router/            # Go Router
│   │   │   ├── theme/             # ThemeCubit, ThemeData
│   │   │   ├── widgets/           # Widgets réutilisables
│   │   │   └── utils/             # Error handling, responsive
│   │   ├── features/              # 15+ modules feature
│   │   └── l10n/                  # Fichiers de localisation
│   ├── assets/
│   │   ├── images/
│   │   ├── translations/
│   │   └── audio/
│   └── pubspec.yaml
│
├── ai_service/
│   ├── app.py                     # Application Flask
│   └── requirements.txt
│
├── iot_service/
│   ├── index.js                   # Service MQTT principal
│   └── config/mosquitto.conf
│
├── nginx/
│   └── hostinger.conf             # Config reverse proxy
│
├── scripts/
│   ├── dev.js                     # Démarrage développement
│   ├── install-all.js             # Installation toutes dépendances
│   └── health-check.js
│
├── logo_extracted/                # 28 variants de logo (16px à 1024px)
│
├── Dockerfile                     # Multi-stage build (backend-runtime + frontend-runtime standalone)
├── docker-compose.yml             # Production (Traefik + VPS)
├── docker-compose.dev.yml         # Développement local (MySQL + Backend + Frontend)
├── .env.docker                    # Variables d'env pour docker-compose.dev.yml
├── ecosystem.config.js            # Config PM2
├── .env / .env.example
├── README.md
├── DEPLOY.md                      # Guide déploiement VPS complet (22 KB)
├── ENV_VARIABLES.md               # Référence 62+ variables d'env
├── COMMANDES_PROJET.md            # Commandes du projet
├── VISITOR_MODE_PROGRESS.md       # Suivi d'avancement mode visiteur
└── BUILD_SUMMARY.md
```

---

## Schéma de base de données (Prisma)

**Provider** : MySQL avec pool de connexions (max 10, timeout 20s)

### Enums clés

```prisma
UserRole      : ADMIN | AGRONOME | PRODUCTEUR | ACHETEUR | FOURNISSEUR | CONSEILLER | PARTENAIRE
UserStatus    : ACTIF | INACTIF | SUSPENDU | EN_ATTENTE
OtpType       : LOGIN | REGISTER | RESET
ParcelleStatus: ACTIVE | EN_REPOS | PREPAREE | ENSEMENCEE | EN_CROISSANCE | RECOLTE
ParcelleHealth: OPTIMAL | SURVEILLANCE | CRITIQUE
StationStatus : ACTIVE | MAINTENANCE | HORS_SERVICE
CapteurType   : HUMIDITE_TEMPERATURE_AMBIANTE | HUMIDITE_SOL | UV | NPK | DIRECTION_VENT | TRANSPIRATION_PLANTE
CapteurStatus : ACTIF | INACTIF | MAINTENANCE | DEFAILLANT
AlertLevel    : INFO | IMPORTANT | CRITIQUE
AlertStatus   : NOUVELLE | LUE | TRAITEE | IGNOREE
CropCategory  : CEREALES | LEGUMINEUSES | TUBERCULES | LEGUMES | ...
StockCategorie: SEMENCES | ENGRAIS | PESTICIDES | HERBICIDES | OUTILS | RECOLTES | AUTRES
MouvementType : ENTREE | SORTIE | AJUSTEMENT | PERTE
```

### Modèles principaux
- **User** — rôles, statut, profil agricole, gamification (points, niveau, badge)
- **Region** — régions administratives de Côte d'Ivoire
- **Cooperative** — coopératives agricoles + membres
- **Parcelle** — parcelles agricoles avec santé, culture, coordonnées GPS
- **Station** — stations IoT liées à une parcelle
- **Capteur** — capteurs (type, statut, seuils d'alerte)
- **Mesure** — données capteurs horodatées (valeur, unité, qualité signal)
- **Alerte** — alertes avec niveau et statut de traitement
- **Recommandation** — recommandations IA
- **MarketplaceProduit** — produits à vendre (5 images, prix, stock)
- **MarketplaceCommande** — commandes avec statut
- **Formation** — contenu pédagogique (video, pdf, article)
- **ProgressionFormation** — suivi de progression utilisateur
- **Stock** — inventaire avec seuils d'alerte et expiration
- **CalendrierActivite** — activités planifiées
- **Diagnostic** — diagnostics IA de maladies
- **DetectionMaladie** — résultats de détection
- **RendementParCulture** — rendements par culture
- **PerformanceParcelle** — métriques de performance
- **RoiTracking** — calcul ROI
- **UserBadge / UserRealisation** — gamification
- **OtpCode** — codes OTP
- **RefreshToken** — gestion tokens JWT
- **Message / Conversation** — messagerie directe
- **ForumPost / ForumReponse** — forum communautaire

---

## Routes API (`/api/v1/...`)

| Préfixe | Contrôleur | Description |
|---------|-----------|-------------|
| `/auth` | authController | Login, register, refresh, OTP |
| `/parcelles` | parcellesController | CRUD parcelles |
| `/cultures` | culturesController | Gestion cultures |
| `/capteurs` | capteursController | Gestion capteurs IoT |
| `/mesures` | mesuresController | Ingestion données capteurs |
| `/alertes` | alertesController | Alertes + lecture |
| `/recommandations` | recommandationsController | Recommandations IA |
| `/diagnostics` | diagnosticsController | Diagnostics maladies IA |
| `/ai` | aiController | Service IA générique |
| `/dashboard` | dashboardController | Stats + KPIs + ROI |
| `/analytics` | analyticsController | Export CSV, comparaisons saisonnières |
| `/marketplace/produits` | marketplaceController | Produits marketplace |
| `/marketplace/commandes` | marketplaceController | Commandes |
| `/formations` | formationsController | Contenu pédagogique |
| `/stocks` | stockController | Inventaire + mouvements |
| `/calendrier` | calendrierController | Activités planifiées |
| `/meteo` | weatherController | Données météo |
| `/fiches-pratiques` | fichesPratiquesController | Base de connaissances |
| `/messages` | chatController | Messagerie directe |
| `/communaute` | communauteController | Forum/posts |
| `/payments` | paymentController | Paiements |
| `/equipment` | equipmentController | Location matériel |
| `/admin` | adminController | Administration |
| `/chatbot` | chatbotController | Assistant IA |

---

## State Management Frontend (Zustand)

Fichier : `/frontend/src/lib/store.ts`

```typescript
useAuthStore      // user, accessToken, refreshToken, login(), logout()
                  // + visitorMode: boolean (NON persisté — mémoire seulement)
                  // + enableVisitorMode() : injecte VISITOR_USER + token fictif
                  // + disableVisitorMode() : reset complet → logout visiteur
                  // Persisté : localStorage (clé "auth-storage")
                  // ⚠️  visitorMode exclu du partialize — disparaît au F5

useParcellesStore // parcelles[], selectedParcelle, CRUD operations

useAlertesStore   // alertes[], unreadCount, markAsRead()

useUIStore        // sidebarOpen, language (fr|baoule|malinke|senoufo), theme
                  // Persisté : localStorage (clé "ui-storage")
```

---

## Flux d'authentification JWT

```
POST /auth/login → { user, accessToken, refreshToken }

Request headers : Authorization: Bearer {accessToken}

Si 401 reçu :
  → POST /auth/refresh { refreshToken }
  → { accessToken, refreshToken }
  → Retry la requête originale
  → File d'attente pour les requêtes concurrentes

Expiration : accessToken 7j, refreshToken 30j
Hachage password : bcryptjs (12 salt rounds)
OTP : via Twilio SMS (LOGIN, REGISTER, RESET)
```

Client Axios avec intercepteurs : `/frontend/src/lib/api.ts`

---

## Variables d'environnement critiques

Référence complète dans `ENV_VARIABLES.md`. Variables essentielles :

```bash
# Base
NODE_ENV=production
PORT=3600
TZ=Africa/Abidjan

# Base de données
DATABASE_URL="mysql://user:pass@host:port/db?connection_limit=10&pool_timeout=20&connect_timeout=10"

# JWT (min 64 caractères)
JWT_SECRET=...
JWT_REFRESH_SECRET=...
JWT_EXPIRES_IN=7d
JWT_REFRESH_EXPIRES_IN=30d

# CORS
ALLOWED_ORIGINS=https://agrosmart.voisilab.online,...
ALLOW_LOCALHOST_CORS=false  # true en développement

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=2000

# Email (SMTP)
SMTP_HOST=...
SMTP_PORT=587
SMTP_USER=...
SMTP_PASSWORD=...
EMAIL_FROM=noreply@agrosmart.ci

# SMS / WhatsApp
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=...
TWILIO_WHATSAPP_NUMBER=...

# Météo
OPENWEATHER_API_KEY=...
WEATHER_API_URL=https://api.open-meteo.com

# Services inter-composants
AI_SERVICE_URL=http://localhost:5001
IOT_SERVICE_URL=http://localhost:4000
IOT_GATEWAY_SECRET=...

# Frontend (variables publiques Next.js)
NEXT_PUBLIC_API_URL=https://api.agrosmart.voisilab.online/api/v1
NEXT_PUBLIC_SOCKET_URL=https://api.agrosmart.voisilab.online

# Logging
LOG_LEVEL=info
LOG_DIR=./logs
```

---

## Commandes de développement

```bash
# Depuis la racine — démarrer tout
node scripts/dev.js

# Installer toutes les dépendances
node scripts/install-all.js

# Backend seul
cd backend && npm run dev     # nodemon
cd backend && npm start       # node

# Frontend seul
cd frontend && npm run dev    # Next.js dev server (port 3603)
cd frontend && npm run build
cd frontend && npm start

# Mobile Flutter
cd mobile && flutter run
cd mobile && flutter build apk
cd mobile && flutter test

# AI Service
cd ai_service && source .venv/bin/activate && flask run --port 5001

# IoT Service
cd iot_service && npm run dev

# Prisma
cd backend && npx prisma generate
cd backend && npx prisma migrate dev
cd backend && npx prisma studio  # Interface BDD visuelle

# Seeding
cd backend && node scripts/seed.js
cd backend && node scripts/seed_admin.js
cd backend && node scripts/seed-complete.js

# Health check
node scripts/health-check.js
```

---

## Déploiement

### PM2 (`ecosystem.config.js`)
```bash
pm2 start ecosystem.config.js
pm2 restart agrismart-backend
pm2 logs agrismart-frontend
pm2 monit
```

| Process | Mode | Mémoire max |
|---------|------|-------------|
| agrismart-backend | cluster (all CPUs) | 500M |
| agrismart-frontend | fork (1 instance) | 400M |
| agrismart-iot | fork | 200M |
| agrismart-ai | fork (gunicorn) | 600M |

### Docker — Développement local (`docker-compose.dev.yml`)

```bash
# Démarrer (build + run)
docker compose -f docker-compose.dev.yml --env-file .env.docker up --build -d

# Rebuild sans cache
docker compose -f docker-compose.dev.yml --env-file .env.docker build --no-cache

# Logs en live
docker compose -f docker-compose.dev.yml logs -f

# Arrêter
docker compose -f docker-compose.dev.yml down
```

**Services** :
| Container | Image | Port hôte | Healthcheck |
|-----------|-------|-----------|-------------|
| agrosmart-mysql | mysql:8.0 | 3307 | mysqladmin ping |
| agrosmart-backend | agrosmartcv-backend | 3600 | GET /health → 200 |
| agrosmart-frontend | agrosmartcv-frontend | 3603 | HTTP 200 |

**Dépendances de démarrage** : MySQL healthy → Backend starts → Backend healthy → Frontend starts

**Entrypoint backend** (`backend/entrypoint.prod.sh`) :
1. Attend MySQL (30 tentatives × 5s)
2. `npx prisma migrate deploy` (fallback : `prisma db push`)
3. Si `RUN_SEED=true` et table users vide → `seed-complete.js` + `seed-all-data.js`
4. `exec node src/server.js`

**Frontend standalone** : `next.config.mjs` → `output: 'standalone'` → image Docker légère via `.next/standalone/server.js`

### Docker — Production (`docker-compose.yml`)

```bash
docker-compose up -d
docker-compose build
docker-compose logs -f backend
```

Targets Dockerfile : `backend-runtime`, `backend-worker-runtime`, `frontend-runtime`

Volumes : `backend_uploads`, `backend_logs`
Réseaux : `app-network` (interne), `traefik-network` (externe)

### Credentials admin par défaut
- Email : `admin@agrosmart.ci`
- Password : `ChangeMe@2024!`

---

## Services métier clés

| Service | Fichier | Rôle |
|---------|---------|------|
| AuthService | `authService.js` | Registration, login, OTP, refresh token |
| AlertesService | `alertesService.js` | Génération et gestion alertes temps réel |
| ParcelleHealthService | `parcelleHealthService.js` | Calcul automatique état de santé parcelle |
| WeatherService | `weatherService.js` | Intégration Open-Meteo + OpenWeather |
| EmailService | `emailService.js` | Envoi emails via Nodemailer |
| SMSGatewayService | `smsGatewayService.js` | SMS/WhatsApp via Twilio |
| PushNotificationService | `pushNotificationService.js` | Notifications push |
| NotificationService | `notificationService.js` | Multi-canal (email, SMS, push) |
| PredictionService | `predictionService.js` | Prédictions ML rendement/maladie |
| PasswordService | `passwordService.js` | Flux reset mot de passe |
| QueueService | `queueService.js` | File de jobs asynchrones |
| HealthCheckService | `healthCheckService.js` | Monitoring santé système |

---

## Middlewares (`/backend/src/middlewares/`)

| Middleware | Fichier | Rôle |
|-----------|---------|------|
| Authentification | `auth.js` | Vérification JWT, validation user actif |
| RBAC | `rbac.js` | Contrôle d'accès basé sur les rôles |
| Validation | `validation.js` | Schémas express-validator |
| Error Handler | `errorHandler.js` | Gestion centralisée des erreurs |
| Rate Limiter | `rateLimiter.js` | Limitation de débit globale + auth |
| Security | `security.js` | Helmet, HPP, CORS |
| Cache Headers | `cacheHeaders.js` | En-têtes de cache HTTP |
| Soft Delete | `softDelete.js` | Suppression logique (isActive) |
| API Versioning | `apiVersioning.js` | Versioning `/api/v1/` |
| Dev Security | `devSecurity.js` | Sécurité spécifique dev |

---

## Sécurité

- **JWT** : HS256, access 7j + refresh 30d avec révocation BDD
- **Passwords** : bcryptjs 12 salt rounds
- **Rate Limiting** : 2000 req/min global
- **CORS** : whitelist configurable + fallback localhost
- **Helmet** : headers HTTP sécurisés
- **HPP** : protection pollution paramètres HTTP
- **Input Validation** : express-validator sur tous les endpoints
- **RBAC** : middleware de contrôle par rôle
- **Soft Delete** : flag `isActive`, pas de suppression physique
- **OTP** : vérification 2FA via SMS Twilio
- **HTTPS** : Let's Encrypt via Certbot/Traefik
- **Pre-commit** : `scripts/pre-commit-security.sh`

---

## Pages Frontend (Next.js App Router)

### Publiques
- `/` — Landing page (hero, features, bénéfices)

### Auth (groupe `(auth)`)
- `/login`
- `/register`
- `/forgot-password`

### Dashboard protégé (groupe `(dashboard)`)
- `/dashboard` — Dashboard principal
- `/parcelles`, `/parcelles/[id]`, `/parcelles/new`, `/parcelles/[id]/edit`
- `/capteurs`
- `/mesures`
- `/meteo`
- `/alertes`
- `/recommandations`
- `/diagnostic`
- `/marketplace`, `/marketplace/[id]`, `/marketplace/nouveau`
- `/formations`, `/formations/[id]`
- `/stocks`
- `/calendrier`
- `/fiches-pratiques`
- `/communaute`, `/communaute/[id]`, `/communaute/nouvelle-discussion`
- `/messages`
- `/performance`
- `/profil`
- `/settings`

### Admin (groupe `(admin)`)
- `/admin` — Dashboard admin
- `/admin/users`
- `/admin/agriculteurs/[id]`
- `/admin/capteurs`
- `/admin/productions`
- `/admin/rapports`
- `/admin/export`
- `/admin/system-settings`
- `/admin/software-updates`

---

## Mobile — Modules Feature Flutter

15+ modules dans `/mobile/lib/features/` :
`auth`, `parcelles`, `marketplace`, `formations`, `diagnostic`, `recommendations`, `messages`, `stocks`, `favorites`, `offline`, `settings`, `buyer_dashboard`, `assistant`, `about`

Pattern : Clean Architecture avec BLoC (Events → BLoC → States)
Offline : Isar local database pour synchronisation hors-ligne

---

## Scripts utilitaires (`/backend/scripts/`)

| Script | Taille | Rôle |
|--------|--------|------|
| `seed.js` | 17.5 KB | Seeding principal BDD |
| `seed-complete.js` | 61.5 KB | Seeding complet avec toutes les données |
| `seed_admin.js` | 4.5 KB | Créer admin initial |
| `seed-iot-capteurs.js` | 6.7 KB | Seeding capteurs IoT |
| `security-audit.js` | 12.8 KB | Audit de sécurité |
| `npm-audit.js` | 7.3 KB | Audit dépendances NPM |
| `db-maintenance.js` | 6.3 KB | Nettoyage et optimisation BDD |
| `prod_validation_e2e.js` | 7.8 KB | Validation E2E production |
| `verify_api_contract.js` | 6.5 KB | Vérification contrat API |

---

## Documentation disponible

| Fichier | Contenu |
|---------|---------|
| `README.md` | Vue d'ensemble, features, tech stack |
| `ENV_VARIABLES.md` | Référence complète des 62+ variables |
| `DEPLOY.md` | Guide déploiement VPS Hostinger complet (22 KB) |
| `COMMANDES_PROJET.md` | Référence commandes (7.8 KB) |
| `BUILD_SUMMARY.md` | Statut du build et commandes de vérification |
| `DEPLOYMENT_SUCCESS.md` | Checklist de succès de déploiement |
| `DOCKER_STATUS.md` | Configuration et statut Docker |
| `backend/scripts/SEED_README.md` | Guide de seeding BDD |
| `mobile/TROUBLESHOOTING.md` | Dépannage Flutter |
| `mobile/EXPLICATION_RENDEMENT.md` | Explication prédiction de rendement |

---

## Mode Visiteur (Demo Mode)

Fonctionnalité permettant à un utilisateur non inscrit d'explorer l'intégralité du dashboard avec des données fictives réalistes, sans aucun appel réseau réel vers le backend.

### Architecture

```
Landing page → bouton "Mode démo"
    ↓
enableVisitorMode()          ← useAuthStore
    → visitorMode = true
    → user = VISITOR_USER    ← lib/mocks/data/user.ts
    → token = 'visitor-demo-token'
    → isAuthenticated = true
    ↓
router.push('/dashboard')
    ↓
(dashboard)/layout.tsx       ← bypass auth si visitorMode === true
    → <VisitorBanner />      ← bannière amber sticky en haut
    ↓
Toute page du dashboard (inchangée)
    ↓
api.get('/quelque-chose')    ← lib/api.ts
    → intercepteur détecte visitorMode
    → config.adapter = visitorMockAdapter
    → mockDispatch(config)   ← lib/mocks/index.ts
    → réponse en ~100-300ms (latence simulée)
    → { success: true, data: <données mockées> }
```

### Fichiers clés

| Fichier | Rôle |
|---------|------|
| `frontend/src/lib/store.ts` | `visitorMode`, `enableVisitorMode()`, `disableVisitorMode()` — non persisté |
| `frontend/src/lib/api.ts` | `visitorMockAdapter` (axios adapter), détection `isVisitorMode()` |
| `frontend/src/lib/mocks/index.ts` | Dispatcher : 50+ routes, table `{p: RegExp, m: string, h: handler}[]` |
| `frontend/src/lib/mocks/helpers.ts` | `daysAgo()`, `hoursAgo()`, `sineSeries()`, `range()` |
| `frontend/src/lib/mocks/data/*.ts` | 16 fichiers de données (un par domaine) |
| `frontend/src/lib/visitorActions.ts` | `enterVisitorMode()`, `exitVisitorMode()`, `exitVisitorModeToRegister()` |
| `frontend/src/components/visitor/VisitorBanner.tsx` | Bannière sticky avec boutons Quitter / Créer un compte |
| `frontend/src/app/(dashboard)/layout.tsx` | Bypass auth guard + montage VisitorBanner |
| `frontend/src/components/landing/Navbar.tsx` | Bouton "Mode démo" |
| `frontend/src/components/landing/HeroSection.tsx` | Bouton "Explorer la démo" + lien secondaire |
| `frontend/src/components/landing/CTASection.tsx` | Bouton "Tester en mode démo" |

### Comportements importants

- **Aucun appel réseau réel** : l'adaptateur axios court-circuite avant l'envoi HTTP. Vérifié : onglet Network DevTools vide.
- **Mutations simulées** : POST/PUT/PATCH/DELETE retournent un succès fictif + toast amber "Mode démo — Créez un compte pour effectuer cette action."
- **Non persisté** : `visitorMode` exclu du `partialize` Zustand. Un F5 sur `/dashboard` redirige vers `/login` (comportement voulu, explicité dans la bannière).
- **Admin bloqué** : le visiteur a le rôle `producteur` — le `(admin)/layout.tsx` bloque l'accès naturellement.
- **Sortie propre** : `disableVisitorMode()` → reset état → redirect `/` ou `/register`.

### Couverture des mocks (endpoints interceptés)

Tous les endpoints appelés par les 26 pages dashboard sont couverts :

```
Auth / User     : /auth/login, /auth/me, /auth/change-password, /users/settings
Dashboard       : /dashboard/stats, /dashboard/kpi, /dashboard/cultures, /dashboard/roi
Weather         : /weather/current, /weather/forecast  (format WMO weather_code)
Parcelles       : CRUD + /parcelles/:id/mesures + /parcelles/:id/stations
Capteurs        : CRUD + /capteurs/:id/toggle + /capteurs/stations
Mesures         : /mesures, /mesures/recent, /mesures/latest (avec timestamp + createdAt aliases)
Alertes         : /alertes, /alertes/:id/read, /alertes/:id/process, /alertes/unread/count
Recommandations : /recommandations, /recommandations/:id/apply, /recommandations/:id/rate
Marketplace     : produits CRUD, commandes, favoris, stats vendeur
Formations      : /formations, /formations/:id, progression
Stocks          : /stocks CRUD, /stocks/statistiques, mouvements
Calendrier      : /calendrier CRUD, prochaines, statistiques, terminer
Fiches pratiques: /fiches-pratiques, search, categories
Messages        : /messages/conversations, /messages/conversations/:id, contacts/search
Communauté      : /communaute/posts (tableau direct), /communaute/stats, leaderboard
Analytics       : /analytics/stats (production_mensuelle + comparaison_saisons + roi + rendements)
Diagnostics     : /diagnostics/history, /diagnostic/analyser
Equipment       : /equipment, my-rentals, requests
AI / Chatbot    : /chatbot, /ai (réponse démo)
Payments        : /payments (simulé)
```

---

## Points d'attention

- Le backend tourne sur le **port 3600**, le frontend sur **3603**
- La variable `ALLOW_LOCALHOST_CORS=true` est nécessaire en développement local
- Les migrations Prisma : `npx prisma migrate dev` (dev) / `npx prisma migrate deploy` (prod)
- Les uploads fichiers sont stockés dans le volume `backend_uploads`
- Le script `entrypoint.prod.sh` gère le démarrage en production avec migration auto
- Marketplace : 5 images max, 5 MB par image (Multer)
- Frontend build nécessite 2048 MB de RAM pour Next.js
- L'AI Service est **optionnel** — le backend fonctionne sans lui
- L'IoT Service est **optionnel** — les capteurs peuvent être saisis manuellement
- Mode visiteur : `visitorMode` non persisté → F5 = retour /login (comportement voulu)
- Docker local : MySQL exposé sur **3307** (évite conflit avec MySQL local sur 3306)
- `next.config.mjs` : `output: 'standalone'` activé — nécessaire pour le Dockerfile frontend

---

## État du projet — Mai 2026

### ✅ Fonctionnel et livré

| Composant | État | Notes |
|-----------|------|-------|
| Backend Express + Prisma | ✅ Complet | 35+ contrôleurs, 38 routes, auth JWT |
| Frontend Next.js | ✅ Complet | 26 pages dashboard + admin + auth |
| Mode Visiteur | ✅ Complet | 50+ routes mockées, 0 appel réseau réel |
| Docker local | ✅ Complet | MySQL + Backend + Frontend, healthchecks |
| Dockerfile multi-stage | ✅ Complet | backend-runtime + frontend-runtime standalone |
| `.env.docker` | ✅ Créé | Variables pour développement Docker local |
| `entrypoint.prod.sh` | ✅ Créé | Wait MySQL → migrate → seed → start |
| Landing page | ✅ Complet | 3 points d'entrée vers le mode démo |
| Couche mocks | ✅ Complète | 16 fichiers de données, TypeScript strict |

### 🔲 Non démarré / Hors scope session

| Composant | État | Notes |
|-----------|------|-------|
| Mobile Flutter | 🔲 Non testé | Code présent, non intégré avec le backend local |
| AI Service (Flask) | 🔲 Non déployé | Optionnel, backend fonctionne sans |
| IoT Service (MQTT) | 🔲 Non déployé | Optionnel, capteurs manuels disponibles |
| Tests automatisés | 🔲 Absents | Pas de tests unitaires/e2e frontend |
| CI/CD pipeline | 🔲 Absent | Déploiement manuel via PM2 ou Docker |
| VPS production | 🔲 À configurer | `agrosmart.voisilab.online`, Traefik + Let's Encrypt |

### Prochaines étapes recommandées

1. **Tester le mode démo end-to-end** dans le navigateur : landing → Mode démo → parcourir 26 pages → vérifier aucune erreur console
2. **Connecter au backend réel** : créer un compte, tester CRUD parcelles/capteurs/alertes
3. **Déployer sur VPS** : copier `.env.docker` → `.env.prod`, adapter les domaines, lancer `docker compose -f docker-compose.yml up -d`
4. **Configurer Traefik** : SSL Let's Encrypt pour `agrosmart.voisilab.online` et `api.agrosmart.voisilab.online`
5. **Tests de charge** : `RATE_LIMIT_MAX_REQUESTS` à ajuster selon trafic réel
