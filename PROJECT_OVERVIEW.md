# AgroSmart — Analyse Complète du Projet

> Document de référence technique — généré le 2026-05-05  
> Couvre : architecture, stack, fonctionnalités, bugs, incohérences

---

## 1. Présentation Générale

**AgroSmart** est un système agricole intelligent conçu spécifiquement pour la **Côte d'Ivoire**.  
L'objectif est d'accompagner les producteurs agricoles avec des outils IoT, IA, marketplace, formation et communauté — accessibles depuis le web, Android et iOS.

- **Domaine prod** : `agrosmart.voisilab.online`
- **API prod** : `api.agrosmart.voisilab.online`
- **Fuseau horaire** : `Africa/Abidjan`
- **Devise** : FCFA
- **Langues** : français (principal), langues locales prévues (via i18n)

---

## 2. Architecture Globale

Le projet est composé de **4 services indépendants** :

```
┌─────────────────────────────────────────────────────┐
│                    TRAEFIK (reverse proxy)           │
│           TLS Let's Encrypt automatique              │
└────────┬──────────────────┬──────────────────────────┘
         │                  │
   ┌─────▼──────┐    ┌──────▼──────┐
   │  Frontend  │    │   Backend   │
   │  Next.js   │    │  Express.js │
   │  Port 3603 │    │  Port 3600  │
   └────────────┘    └──────┬──────┘
                            │
              ┌─────────────┼──────────────┐
              │             │              │
       ┌──────▼─────┐ ┌─────▼─────┐ ┌─────▼────┐
       │ AI Service │ │IoT Service│ │  MySQL   │
       │ Flask/TF   │ │ MQTT/Node │ │  (hôte)  │
       │ Port 5001  │ │ Port 4000 │ └──────────┘
       └────────────┘ └───────────┘
```

**Application mobile :** Flutter (Android + iOS), architecture Clean Architecture + BLoC.

---

## 3. Stack Technique

### Backend
| Élément | Technologie |
|---|---|
| Runtime | Node.js >= 20 |
| Framework | Express.js v5 |
| ORM | Prisma v6 |
| Base de données | MySQL (MariaDB compatible) |
| Auth | JWT (access 7j + refresh 30j) |
| WebSocket | Socket.IO v4 |
| SMS/WhatsApp | Twilio |
| Email | Nodemailer |
| Logs | Winston + Daily Rotate File |
| Rate limiting | express-rate-limit |
| Sécurité | Helmet, HPP, CORS, bcryptjs |
| Doc API | Swagger (swagger-jsdoc + swagger-ui-express) |

### Frontend
| Élément | Technologie |
|---|---|
| Framework | Next.js v16 (App Router) |
| UI | Tailwind CSS v4 + Radix UI |
| State | Zustand v5 |
| Forms | React Hook Form + Zod v4 |
| Graphiques | Recharts v3 |
| Animations | Framer Motion v12 |
| i18n | i18next + react-i18next |
| HTTP | Axios 1.15.1 |
| WebSocket | Socket.IO Client v4 |

### Mobile
| Élément | Technologie |
|---|---|
| Framework | Flutter (SDK ^3.10.1) |
| State | Flutter BLoC v9 |
| Architecture | Clean Architecture (Domain/Data/Presentation) |
| HTTP | Dio v5 |
| Router | go_router v17 |
| DB locale | Isar v3 (offline) |
| Auth locale | flutter_secure_storage |
| Maps | flutter_map + latlong2 |
| Scanner | mobile_scanner v7 (QR codes) |
| TTS/STT | flutter_tts + speech_to_text |
| Biométrie | local_auth v2 |

### AI Service
| Élément | Technologie |
|---|---|
| Runtime | Python 3 |
| Framework | Flask |
| ML | TensorFlow (optionnel — mode dégradé si absent) |
| Endpoints | `/predict/disease` (image), `/predict/irrigation` (JSON) |

### IoT Service
| Élément | Technologie |
|---|---|
| Runtime | Node.js |
| Protocole | MQTT |
| Broker défaut | `test.mosquitto.org` (dev) |
| Topic | `agrosmart/+/up` |

---

## 4. Déploiement

### Option A — Docker + Traefik (recommandé prod)
- `docker-compose.yml` à la racine
- `Dockerfile` multi-stage (backend-runtime + frontend-runtime)
- Worker IoT commenté, activable avec `COMPOSE_PROFILES=worker`
- Volumes : `backend_uploads`, `backend_logs`

### Option B — PM2 + Nginx (sans Docker)
- `ecosystem.config.js` — backend en cluster mode (tous les CPUs), frontend sur port 3603
- `backend/nginx.conf` — reverse proxy, rate limiting, HTTPS redirect
- `backend/entrypoint.prod.sh` — script de démarrage prod

---

## 5. Base de Données — Schéma Prisma

### Modèles principaux (33 tables)

| Modèle | Description |
|---|---|
| `User` | Agriculteurs, conseillers, acheteurs, admins... |
| `Parcelle` | Champs agricoles géolocalisés |
| `Station` | Stations IoT attachées aux parcelles |
| `Capteur` | Capteurs individuels (humidité, T°, NPK…) |
| `Mesure` | Mesures IoT time-series |
| `Alerte` | Alertes capteur/système |
| `Culture` | Catalogue de cultures |
| `Plantation` | Plantations actives sur parcelles |
| `Recolte` | Récoltes liées aux plantations |
| `MarketplaceProduit` | Produits du marketplace |
| `MarketplaceCommande` | Commandes |
| `Cart` / `CartItem` | Panier |
| `Favorite` / `Wishlist` | Favoris & liste de souhaits |
| `Avis` | Notes et avis produits |
| `Formation` | Modules de formation |
| `ProgressionFormation` | Suivi de progression par utilisateur |
| `ForumPost` / `ForumReponse` | Forum communautaire |
| `Message` / `Conversation` | Messagerie privée |
| `Diagnostic` | Diagnostics maladies |
| `DetectionMaladie` | Détections IA |
| `Maladie` | Base de données maladies |
| `Recommandation` | Recommandations IA personnalisées |
| `Stock` / `MouvementStock` | Gestion des stocks agricoles |
| `CalendrierActivite` | Planning agricole |
| `AchatGroupe` | Achats groupés |
| `EquipementLocation` / `Location` | Location de matériel |
| `Badge` / `UserBadge` | Gamification |
| `Realisation` | Réalisations/succès |
| `RoiTracking` | Suivi ROI |
| `Economies` | Économies réalisées |
| `Meteo` | Cache météo |
| `Configuration` | Paramètres système |
| `RefreshToken` | Tokens de rafraîchissement JWT |
| `OtpCode` | Codes OTP |
| `AuditLog` / `ActivitiesLog` | Logs d'audit |

### Enums importants
- **UserRole** : `ADMIN`, `AGRONOME`, `PRODUCTEUR`, `ACHETEUR`, `FOURNISSEUR`, `CONSEILLER`, `PARTENAIRE`
- **CapteurType** : `HUMIDITE_TEMPERATURE_AMBIANTE`, `HUMIDITE_SOL`, `UV`, `NPK`, `DIRECTION_VENT`, `TRANSPIRATION_PLANTE`
- **ParcelleStatus** : `ACTIVE`, `EN_REPOS`, `PREPAREE`, `ENSEMENCEE`, `EN_CROISSANCE`, `RECOLTE`

---

## 6. Authentification & Sécurité

### Flux d'authentification
1. **Inscription** → Hash bcrypt (salt 12) → statut `ACTIF` immédiat (TODO: OTP désactivé)
2. **Login** → `identifier` (email ou téléphone) + mot de passe → `accessToken` (7j) + `refreshToken` (30j)
3. **OTP** : infrastructure en place (`OtpCode` table) mais **non activé en prod** (commenté)
4. **Refresh** : refresh token stocké en DB, révocable
5. **Logout** : révocation du refresh token

### RBAC (middleware rbac.js)
```
ADMIN (4) > CONSEILLER (3) > PARTENAIRE (2) > PRODUCTEUR (1) = ACHETEUR (1)
```
- `requireRole(...roles)` — whitelist stricte
- `requireMinRole(minRole)` — hiérarchie
- `requireOwnership(fn)` — propriété de ressource
- `requireParcelleAccess` — accès parcelle avec vérification
- `requireCapteurAccess` — accès capteur avec vérification

### Sécurité additionnelle
- Rate limiting global : 2000 req/min (configurable)
- Rate limiting auth : 10 req/15min sur `/auth/login` et `/auth/otp`
- Protection brute-force sur login/OTP (middleware `security.js`)
- Helmet CSP activé en prod
- CORS : whitelist configurable via `CORS_ORIGIN`/`ALLOWED_ORIGINS`

---

## 7. API Backend — Routes principales

Toutes les routes sont montées sous `/api/v1/` :

| Préfixe | Description |
|---|---|
| `/auth` | Inscription, login, OTP, refresh, logout |
| `/users` | Profil utilisateur, paramètres |
| `/regions` | Régions de Côte d'Ivoire |
| `/parcelles` | CRUD parcelles |
| `/capteurs` | CRUD capteurs IoT |
| `/mesures` | Mesures time-series |
| `/alertes` | Alertes système |
| `/cultures` | Catalogue cultures |
| `/maladies` | Base maladies |
| `/diagnostics` | Diagnostics IA |
| `/recommandations` | Recommandations personnalisées |
| `/marketplace` | Produits, recherche |
| `/cart` | Panier |
| `/favorites` | Favoris |
| `/wishlist` | Liste de souhaits |
| `/reviews` | Avis produits |
| `/payments` | Mobile Money (Orange, MTN, Moov) |
| `/group-purchases` | Achats groupés |
| `/equipment` | Location matériel |
| `/messages` | Messagerie privée |
| `/chat` | Chat temps réel |
| `/chatbot` | Chatbot IA |
| `/communaute` | Forum |
| `/sms` | Envoi SMS |
| `/formations` | Formations + progression |
| `/fiches-pratiques` | Bibliothèque agricole |
| `/weather` | Météo (Open-Meteo / OpenWeather) |
| `/analytics` | Analytics et reporting |
| `/gamification` | Points, badges, réalisations |
| `/stocks` | Gestion stocks agricoles |
| `/calendrier` | Planning activités agricoles |
| `/upload` | Upload images |
| `/ai` | Prédictions IA (délégation vers ai_service) |
| `/admin` | Administration |
| `/dashboard` | Dashboard producteur |
| `/demo` | **Routes publiques** (mode visiteur, sans auth) |

---

## 8. Mode Visiteur (Discovery Mode)

Fonctionnalité récente (commits `5b9fbbb`, `eb4fb27`) permettant de découvrir la plateforme sans compte.

**Backend** — routes publiques sans JWT :
- `GET /api/v1/demo/parcelles` — 3 parcelles simulées
- `GET /api/v1/demo/alertes` — alertes type
- `GET /api/v1/demo/recommandations` — recommandations IA simulées
- `GET /api/v1/demo/stats` — statistiques globales
- `GET /api/v1/demo/features` — liste des fonctionnalités

**Frontend** :
- Page `/demo` avec données simulées locales + appels backend optionnels
- Hook `useGeolocation` pour afficher la position de l'utilisateur
- `discoveryMode.ts` — flag `sessionStorage` pour le mode visiteur

---

## 9. Application Mobile Flutter

### Architecture
Clean Architecture stricte avec 3 couches :
- **Domain** : entités, repositories (interfaces), use cases
- **Data** : implémentations repositories, datasources (remote + local Isar)
- **Presentation** : BLoC, pages, widgets

### Features implémentées
`auth`, `parcelles`, `capteurs`, `mesures`, `monitoring`, `alertes`, `diagnostics`, `weather`, `marketplace`, `cart`, `checkout`, `orders`, `favorites`, `formations`, `forum`, `community`, `messages`, `notifications`, `calendrier`, `stocks`, `recommandations`, `analytics`, `gamification`, `profile`, `settings`, `dashboard`, `buyer_dashboard`, `irrigation`, `offline`, `qr_scanner`, `support`

### Spécificités
- Support offline via Isar (DB locale)
- Biométrie (local_auth)
- TTS/STT pour accessibilité
- QR Scanner pour équipements
- Thème clair/sombre (ThemeCubit)
- i18n avec ARB files
- Configuration multi-env via `--dart-define APP_ENV`

---

## 10. Services Auxiliaires

### AI Service (Python/Flask — Port 5001)
- **Mode dégradé** : démarre même sans TensorFlow (retourne 503 sur les endpoints ML)
- `/predict/disease` : analyse image → détection maladie (4 classes : Saine, Rouille, Tache Foliaire, Mildiou)
- `/predict/irrigation` : données capteurs → quantité d'eau recommandée
- Modèles attendus : `models/disease_model.h5`, `models/irrigation_model.h5`

### IoT Service (Node.js/MQTT — Port 4000)
- Souscription MQTT sur topic `agrosmart/+/up`
- Décodage JSON des payloads capteurs
- Transmission au backend via `sensorWorker.js` (traitement synchrone)
- `sensorWorker.js` : mappe les `device_code` → Station → Capteurs → insertion `Mesure` → calcul santé parcelle → alertes

---

## 11. WebSocket (Socket.IO)

Événements émis par le backend :
- `alert:new` → room `user_{userId}`
- `measurement:new` → room `parcelle:{parcelleId}`

Authentification WebSocket via JWT dans le handshake.

---

## 12. Variables d'Environnement Clés

| Variable | Usage |
|---|---|
| `DATABASE_URL` | URL Prisma MySQL |
| `JWT_SECRET` | Clé access token |
| `JWT_REFRESH_SECRET` | Clé refresh token |
| `CORS_ORIGIN` / `ALLOWED_ORIGINS` | Whitelist CORS |
| `WEATHER_API_URL` | Open-Meteo |
| `OPENWEATHER_API_KEY` | OpenWeatherMap |
| `AI_SERVICE_URL` | URL microservice Flask |
| `IOT_SERVICE_URL` | URL service IoT |
| `TWILIO_*` | SMS/WhatsApp |
| `SMTP_*` | Email |
| `NEXT_PUBLIC_API_URL` | URL API côté frontend |
| `NEXT_PUBLIC_SOCKET_URL` | URL WebSocket côté frontend |

---

## 13. Scripts Utiles

```bash
# Backend
npm run dev                   # Développement (nodemon)
npm run db:migrate            # Migration prod
npm run db:seed               # Seed de base
npm run test:prod-validation  # Validation E2E prod
npm run test:platform-validation # Validation complète plateforme
npm run audit:security        # Audit de sécurité

# Docker
docker compose up -d          # Démarrer backend + frontend
docker compose --profile worker up -d  # + IoT worker

# PM2
pm2 start ecosystem.config.js
```

---

## 14. BUGS ET INCOHÉRENCES DÉTECTÉS

### 🔴 BUG CRITIQUE — `AGRONOME` dans les routes mais absent du RBAC

**Fichier** : [`backend/src/routes/fichesPratiques.js:19-20`](backend/src/routes/fichesPratiques.js)

```js
// Ces lignes référencent le rôle 'AGRONOME'
router.post('/', authenticate, requireRole('ADMIN', 'CONSEILLER', 'AGRONOME'), ...);
router.put('/:id', authenticate, requireRole('ADMIN', 'CONSEILLER', 'AGRONOME'), ...);
```

**Problème** : Le rôle `AGRONOME` existe dans l'enum `UserRole` du schéma Prisma, mais il **n'est pas déclaré** dans la constante `ROLES` du middleware [`backend/src/middlewares/rbac.js`](backend/src/middlewares/rbac.js). `requireRole` compare `req.user.role` avec les arguments passés, ce qui fonctionnera quand même (comparaison de strings), mais `AGRONOME` n'a pas de niveau dans `ROLE_HIERARCHY` (retourne `undefined` → 0), ce qui cassera `requireMinRole` pour ce rôle.

**Fix** : Ajouter `AGRONOME` dans `ROLES` et lui attribuer un niveau dans `ROLE_HIERARCHY`.

---

### 🔴 BUG — `FOURNISSEUR` non géré dans le RBAC

**Fichier** : [`backend/src/middlewares/rbac.js`](backend/src/middlewares/rbac.js)

Le rôle `FOURNISSEUR` est présent dans l'enum Prisma `UserRole` mais absent de `ROLES` et `ROLE_HIERARCHY`. Un utilisateur avec ce rôle ne pourra accéder à aucune route sans traitement spécifique.

---

### 🟠 INCOHÉRENCE — Rôles en majuscules (backend) vs minuscules (frontend)

**Fichier** : [`frontend/src/lib/store.ts:13`](frontend/src/lib/store.ts)

```ts
// Frontend
role: 'producteur' | 'conseiller' | 'admin' | 'partenaire'

// Backend retourne
role: 'PRODUCTEUR' | 'CONSEILLER' | 'ADMIN' | 'PARTENAIRE'
```

Les rôles côté frontend sont définis en minuscules dans le type TypeScript, mais l'API backend retourne des majuscules. Toute comparaison `user.role === 'admin'` échouera silencieusement. À vérifier si des vérifications de rôle existent côté frontend (accès à `/admin`, etc.).

---

### 🟠 BUG — Mapping IoT `temperature` → `HUMIDITE_TEMPERATURE_AMBIANTE` (doublon)

**Fichier** : [`backend/src/workers/sensorWorker.js`](backend/src/workers/sensorWorker.js)

```js
if (type === 'humidity') dbType = 'humidite_temperature_ambiante';
if (type === 'soil_moisture') dbType = 'humidite_sol';
if (type === 'temperature') dbType = 'humidite_temperature_ambiante'; // ← MÊME valeur que humidity !
```

Les deux types `humidity` et `temperature` pointent vers le même `CapteurType` enum (`HUMIDITE_TEMPERATURE_AMBIANTE`). Le capteur de type `HUMIDITE_TEMPERATURE_AMBIANTE` gère effectivement température + humidité ambiante ensemble (c'est un capteur combiné type DHT22), mais cela signifie que lors de la recherche du capteur par type, les deux mesures (`temperature` et `humidity`) vont chercher le même capteur — ce qui est correct si le capteur est de type combiné. Cependant, les commentaires laissés dans le code montrent une confusion sur cette intention (le développeur lui-même a douté).

**Risque** : Si une station a un capteur `HUMIDITE_TEMPERATURE_AMBIANTE` et un capteur `UV`, une mesure `temperature` sera bien enregistrée, mais la logique n'est pas évidente. À documenter clairement.

---

### 🟡 DETTE TECHNIQUE — OTP non activé en production

**Fichier** : [`backend/src/services/authService.js:54`](backend/src/services/authService.js)

```js
// TODO: Remettre EN_ATTENTE une fois que la vérification OTP/Email sera activée
const initialStatus = 'ACTIF';
```

Les comptes sont créés directement en statut `ACTIF` sans vérification téléphone/email. L'infrastructure OTP est prête (table `OtpCode`, envoi SMS via Twilio commenté) mais désactivée. Risque de comptes non vérifiés.

---

### 🟡 DETTE TECHNIQUE — `UserFormationLegacy` : table fantôme sans relations

**Fichier** : [`backend/prisma/schema.prisma:1236-1250`](backend/prisma/schema.prisma)

```prisma
model UserFormationLegacy {
  // No relations defined to avoid modifying User/Formation models.
```

Ce modèle mappe la table `user_formations` (ancienne) sans relations Prisma explicites. Si des requêtes passent par ce modèle, elles ne peuvent pas utiliser `include`/`select` sur les relations. Le modèle `ProgressionFormation` est le remplacement correct, mais les deux coexistent.

---

### 🟡 COMMENTAIRE ERRONÉ dans le code source

**Fichier** : [`backend/src/middlewares/auth.js:222-229`](backend/src/middlewares/auth.js)

Un long commentaire dans `verifyRefreshToken` affirme que `langue_preferee` n'existe pas dans le schéma Prisma — ce qui est **faux** (ligne 200 du schéma le définit). Le commentaire est resté après investigation et crée de la confusion. À supprimer.

---

### 🟡 INCOHÉRENCE — Paiement Mobile Money sans intégration provider réelle

**Fichier** : [`backend/src/controllers/paymentController.js`](backend/src/controllers/paymentController.js)

```js
payment_url: null,
provider_status: 'pending_provider_confirmation'
```

Le controller crée bien la transaction en DB mais ne fait **aucun appel réel** vers Orange Money, MTN Money ou Moov Money. Les paiements restent indéfiniment en statut `en_attente`. La couche provider API est à implémenter.

---

### 🟡 Worker IoT commenté dans docker-compose.yml

**Fichier** : [`docker-compose.yml:52-67`](docker-compose.yml)

Le service `backend-worker` (IoT) est entièrement commenté. Si le service IoT MQTT doit fonctionner en Docker, il faut le décommenter et configurer le `COMPOSE_PROFILES`.

---

### 🟡 MQTT Broker public par défaut (dev)

**Fichier** : [`iot_service/index.js`](iot_service/index.js)

```js
const MQTT_BROKER = process.env.MQTT_BROKER_URL || 'mqtt://test.mosquitto.org';
```

Le broker par défaut est public (`test.mosquitto.org`). En cas d'oubli de configuration, les données IoT seraient envoyées sur un broker public — risque de fuite de données en production.

---

### 🟡 Rate limit trop élevé (2000 req/min)

**Fichier** : [`.env.example`](.env.example)

```
RATE_LIMIT_MAX_REQUESTS=2000
```

2000 requêtes par minute par IP est très permissif. Pour une plateforme agricole, une valeur de 100-200 req/min serait plus adaptée et protégerait mieux contre les abus.

---

### 🟡 Absence de tests automatisés

Aucun fichier de test (`.spec.js`, `.test.js`, `__tests__/`) n'est présent dans les répertoires `backend/src/` ou `frontend/src/`. Les fichiers de validation sont des scripts E2E manuels. Les `bloc_test` et `mocktail` sont commentés dans le `pubspec.yaml` mobile pour cause de conflits.

---

### 🔵 INFO — AI models non inclus dans le repo

Les modèles TensorFlow (`models/disease_model.h5`, `models/irrigation_model.h5`) ne sont pas dans le repository. Le service IA fonctionne en mode dégradé (503) sans eux. Un mécanisme de provisioning des modèles est à prévoir (S3, DVC, etc.).

---

### 🔵 INFO — `bloc_test` et `mocktail` désactivés en mobile

**Fichier** : [`mobile/pubspec.yaml`](mobile/pubspec.yaml)

```yaml
# bloc_test et mocktail sont commentés car ils causent des conflits avec isar_generator
```

Les tests BLoC sont bloqués par un conflit de dépendances avec `isar_generator`. À résoudre pour pouvoir écrire des tests unitaires côté mobile.

---

## 15. Résumé des Points Forts

- Architecture bien séparée (4 microservices)
- Schéma Prisma très complet avec soft delete, indexes, audit logs
- Sécurité solide : JWT double token, bcrypt salt 12, Helmet, rate limiting, RBAC hiérarchique
- Mode dégradé IA (pas de crash si TF absent)
- Mode visiteur fonctionnel pour l'onboarding
- Application mobile avec support offline (Isar), biométrie, accessibilité (TTS/STT)
- Deploy flexible : Docker + Traefik OU PM2 + Nginx

## 16. Priorités de Correction Suggérées

1. **[P0]** Ajouter `AGRONOME` et `FOURNISSEUR` dans `ROLES` et `ROLE_HIERARCHY` du RBAC
2. **[P0]** Normaliser les rôles frontend (passer en majuscules ou mapper côté API)
3. **[P1]** Activer la vérification OTP à l'inscription (Twilio configuré)
4. **[P1]** Implémenter les intégrations providers Mobile Money (Orange, MTN, Moov)
5. **[P2]** Clarifier et documenter le mapping IoT `temperature`/`humidity` → `HUMIDITE_TEMPERATURE_AMBIANTE`
6. **[P2]** Supprimer le commentaire erroné sur `langue_preferee` dans `auth.js`
7. **[P2]** Réduire le rate limit par défaut (2000 → 200 req/min)
8. **[P2]** Configurer un broker MQTT privé en prod (ne pas utiliser le broker public)
9. **[P3]** Résoudre le conflit `isar_generator` vs `bloc_test` pour activer les tests mobile
10. **[P3]** Ajouter un mécanisme de provisioning pour les modèles IA
