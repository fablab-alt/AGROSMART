# CLAUDE.md — AgroSmart CI

---
## Règles de maintenance
- Limite stricte : 250 lignes. Compresser avant d'ajouter.
- Mettre à jour quand : nouvelle route API, nouveau modèle Prisma, nouveau service, changement de port ou de stack.
- Pas de mise à jour pour : bugfix, refactor interne, modification de logique sans impact sur la structure.
- Format imposé : tableaux et blocs de code uniquement, zéro narratif.
- Section "État actuel" : réécrire entièrement à chaque mise à jour, 6 lignes max.
- SESSIONS.md : ne mettre à jour que sur demande explicite de l'utilisateur.
---

## Standards de développement — Non négociables

### Qualité & Maintenabilité
- Zéro code mort : aucune fonction, variable, import, route ou composant inutilisé
- Zéro valeur hardcodée : constantes nommées ou variables d'environnement systématiquement
- Zéro catch vide : toute erreur est loggée et gérée explicitement
- Zéro logique métier dans les routes, controllers ou composants UI
- Nommage : explicite, cohérent avec le reste du projet, en anglais pour le code
- Commentaires uniquement si la logique n'est pas évidente à la lecture
- Une fonction = une responsabilité · max 40 lignes · sinon découper

### Architecture
- Séparation stricte : routes → controllers → services → repositories → BDD
- Pas de couplage entre couches non adjacentes
- Config centralisée, jamais dispersée dans les fichiers métier
- Variables d'environnement validées au démarrage, jamais accédées dans le code métier
- Dépendances injectées, jamais instanciées directement dans le code métier

### Nommage & Structure
- Dossiers : kebab-case · Modules : kebab-case · Composants React/Flutter : PascalCase
- Variables/fonctions : camelCase · Constantes : SCREAMING_SNAKE_CASE · Classes/types : PascalCase
- Préfixes : `use` hooks · `I` interfaces TS · `T` types TS
- Structure dossiers cohérente avec l'architecture définie dans ce fichier

### Sécurité
- Toute entrée validée et sanitizée côté backend avant traitement
- Auth vérifiée sur chaque route protégée · RBAC après auth, pas uniquement via middleware global
- Jamais de secret/token/clé en clair dans le code ou les logs · placeholders explicites
- Rate limiting sur toutes les routes publiques · Helmet systématique
- Signaler toute dépendance avec vulnérabilité connue

### Base de données
- Requêtes préparées systématiquement, jamais de concaténation SQL
- Index sur toutes les colonnes utilisées en WHERE, JOIN, ORDER BY
- Pas de SELECT * en production · Transactions pour toute opération multi-tables
- Soft delete cohérent (`isActive`) · Migrations versionnées · Jamais de `db push` en production
- Chaque modèle Prisma a `createdAt` et `updatedAt`

### Web (Next.js / React)
- App Router · Server Components si pas d'interactivité cliente
- Pas de `useEffect` pour du fetching : Server Actions ou React Query
- États globaux Zustand uniquement · pas de prop drilling >2 niveaux
- Accessibilité : `aria-label`, `alt`, rôles sémantiques · Tailwind uniquement, zéro inline styles
- Chaque page gère explicitement les états : loading, error, empty

### Mobile (Flutter)
- Clean Architecture stricte : entities → repository abstrait → datasource → bloc/cubit
- Zéro logique métier dans les widgets · get_it pour l'injection systématiquement
- Responsive : LayoutBuilder ou MediaQuery · zéro valeur fixe en px
- Chaque bloc a ses états : initial, loading, success, failure

### Node.js / Backend
- Async/await systématiquement · middleware d'erreur centralisé · zéro try/catch dupliqué par route
- Logs Winston : niveau approprié · zéro `console.log` en production
- Pagination obligatoire sur toute route retournant une liste
- Format réponse uniforme sur tout le projet : `{ success, data, message, meta }`

### Scalabilité
- Zéro logique bloquante synchrone sur opérations longues : jobs asynchrones
- Cache sur données fréquemment lues · Zéro N+1 : includes/joins Prisma explicites
- Workers pour traitements découplés du cycle requête/réponse

### Processus
- Tester chaque fonctionnalité avant la suivante
- Échec : lire l'erreur complète · vérifier si problème connu · avant de modifier
- Bloqué >10 min : écrire dans BLOCKERS.md avant toute autre action
- Jamais supprimer un fichier ou modifier un schéma BDD sans validation explicite
- Signaler code mort et violations des standards · ne pas corriger sauf demande explicite

---

## Vue d'ensemble

Plateforme agricole intelligente pour la Côte d'Ivoire (IoT, IA, analyse prédictive). Fichiers locaux, pas de branches Git. Domaine prod : `agrosmart.voisilab.online`. Ports : backend **3600**, frontend **3603**. Journal → `SESSIONS.md`.

---

## Tech Stack

| Service | Stack |
|---------|-------|
| Backend | Node.js 22 · Express 5 · Prisma 6 · MySQL 8 · Socket.IO · JWT · PM2 |
| Frontend | Next.js 16 · React 19 · TypeScript · Tailwind 4 · Zustand · Axios · Recharts |
| Mobile | Flutter 3.10 · BLoC · Dio · Isar · go_router · get_it |
| AI Service | Python 3.11 · Flask · TensorFlow 2.20 · Gunicorn :5001 |
| IoT Service | Node.js · MQTT :4000 |
| Infra | Docker multi-stage · PM2 cluster · Nginx · Let's Encrypt · Traefik |

---

## Schéma BDD

```
UserRole         : ADMIN | AGRONOME | PRODUCTEUR | ACHETEUR | FOURNISSEUR | CONSEILLER | PARTENAIRE
UserStatus       : ACTIF | INACTIF | SUSPENDU | EN_ATTENTE
ParcelleHealth   : OPTIMAL | SURVEILLANCE | CRITIQUE
CapteurType      : HUMIDITE_TEMPERATURE_AMBIANTE | HUMIDITE_SOL | UV | NPK | DIRECTION_VENT | TRANSPIRATION_PLANTE
AlertLevel/Status: INFO | IMPORTANT | CRITIQUE · NOUVELLE | LUE | TRAITEE | IGNOREE
FriendshipStatus : PENDING | ACCEPTED | REJECTED | BLOCKED
StockCategorie   : SEMENCES | ENGRAIS | PESTICIDES | HERBICIDES | OUTILS | RECOLTES | AUTRES
```

| Modèle | Notes |
|--------|-------|
| User | rôles, statut, GPS (latitude/longitude), gamification |
| Region | régions CI, endpoint public `/regions` |
| Cooperative | coopératives + membres |
| Parcelle | santé, culture, coords GPS |
| Station · Capteur · Mesure | IoT — types, seuils, données horodatées |
| Alerte · Recommandation | niveau + statut traitement |
| Diagnostic | détection maladies IA |
| MarketplaceProduit | vente + location (`typeOffre/prixLocationJour/caution`) |
| MarketplaceCommande | statut commande |
| Formation · ProgressionFormation | contenu + suivi |
| Stock · CalendrierActivite | inventaire + planning |
| RendementParCulture · PerformanceParcelle · RoiTracking | analytics |
| UserBadge · OtpCode · RefreshToken | auth + gamification |
| Message · Conversation | messagerie directe |
| ForumPost · ForumReponse | soft-delete (`isActive`), compteurs `likes/upvotes` |
| ForumPostLike · ForumReponseUpvote | tables jointure — unicité par user |
| Friendship | `requesterId/addresseeId` + status |

---

## Routes API (`/api/v1/...`)

| Préfixe | Contrôleur | Description |
|---------|-----------|-------------|
| `/auth` | authController | Login, register, refresh, OTP |
| `/regions` | — | Régions CI (public, sans auth) |
| `/parcelles` | parcellesController | CRUD parcelles |
| `/capteurs` | capteursController | CRUD capteurs IoT |
| `/mesures` | mesuresController | Ingestion données capteurs |
| `/alertes` | alertesController | Alertes + lecture |
| `/recommandations` | recommandationsController | Recommandations IA |
| `/diagnostics` | diagnosticsController | Diagnostics maladies IA |
| `/dashboard` | dashboardController | Stats + KPIs + ROI |
| `/analytics` | analyticsController | Export CSV, comparaisons |
| `/marketplace/produits` | marketplaceController | Produits vente/location |
| `/marketplace/commandes` | marketplaceController | Commandes |
| `/formations` | formationsController | Contenu pédagogique |
| `/stocks` | stockController | Inventaire + mouvements |
| `/calendrier` | calendrierController | Activités planifiées |
| `/weather` | weatherController | Météo voisilab IoT (capteurs CI, prévisions IA 4 horizons) |
| `/fiches-pratiques` | fichesPratiquesController | Base de connaissances |
| `/messages` | chatController | Messagerie directe |
| `/communaute` | communauteController | Forum complet + likes/upvotes |
| `/friendships` | friendshipsController | Réseau social amis |
| `/equipment` | equipmentController | Location matériel |
| `/payments` | paymentController | Paiements |
| `/chatbot` | chatbotController | Assistant IA |
| `/ai` | aiController | Service IA générique |
| `/admin` | adminController | Administration |

---

## State Zustand — `frontend/src/lib/store.ts`

```
useAuthStore      : user, token, login/logout, visitorMode (non persisté), enableVisitorMode/disableVisitorMode
useParcellesStore : parcelles[], selectedParcelle, CRUD
useAlertesStore   : alertes[], unreadCount, markAsRead()
useUIStore        : sidebarOpen, language, theme  [persisté "ui-storage"]
```

---

## Flux Auth JWT

```
POST /auth/login → { user, accessToken (7j), refreshToken (30j) }
Si 401 → POST /auth/refresh → retry (file d'attente concurrente)
bcryptjs 12 rounds · OTP Twilio SMS · visitorMockAdapter court-circuite axios en mode démo
```

---

## État actuel — Mai 2026

| | |
|--|--|
| ✅ Fonctionnel | Backend 39 routes · Frontend 27 pages · Mode visiteur 60+ mocks · Docker dev+prod · Forum likes/upvotes · Réseau social `/amis` + mobile · Marketplace location · GPS inscription · Météo voisilab IoT (capteurs CI + IA 4 horizons, précipitations + luminosité) · store.ts types capteurs alignés Prisma · GitHub `fablab-alt/AGROSMART` |
| 🔲 Non déployé | VPS prod · AI Service Flask · IoT MQTT · Tests automatisés · CI/CD |
| 🎯 Priorité | `flutter run` → tester friendships · `prisma migrate dev` propre · déployer VPS + Traefik SSL |

## Service Météo — voisilab IoT

```
Source : https://meteo.voisilab.online/api  (WEATHER_API_URL)
Stations : 3 nœuds IoT (node-001/002/003) avec lat/lon en CI
Sélection : station la plus proche par distance haversine
Endpoints consommés :
  GET /api/nodes                  → liste des stations (cache 1h)
  GET /api/sensor-data?node_id=&limit=1  → mesure actuelle
  GET /api/ai/predict/:nodeId     → prévisions IA (3h·6h·12h·24h)
  GET /api/alerts                 → alertes RAIN/ANOMALY
Données : température, humidité, pression, vent, pluie, luminosité, anomalie_score
Dérivé   : code WMO approché (deriveWeatherCode), ETP approché (estimateEtp)
```
