# Journal des sessions — AgroSmart CI

---
## Règles de maintenance
- Ne mettre à jour ce fichier que sur demande explicite de l'utilisateur.
- Format imposé : une entrée par session, 10 bullets max, aucun détail narratif.
- Après chaque session : ajouter une entrée en haut du journal (ordre antéchronologique).
- Garder uniquement : décisions architecturales, workarounds non évidents, état final.
- Supprimer : causes de bugs, explications intermédiaires, tout ce qui est dans le code.
---

---

### 2026-05-12 — Météo voisilab IoT + couverture capteurs complète + uniformité dashboard/meteo

**Fichiers principaux :** `weatherService.js` · `weatherController.js` · `meteo/page.tsx` · `dashboard/page.tsx` · `mocks/index.ts` · `store.ts` · `iot_service/index.js` · `validation.js` · `.env.docker`
**État final :** Fonctionnel

- Migration météo : Open-Meteo → voisilab IoT (`https://meteo.voisilab.online/api`), sélection station par haversine
- `weatherService.js` : réécriture complète — `deriveWeatherCode`, `estimateEtp`, cache mémoire, prévisions IA 4 horizons (3h/6h/12h/24h)
- Bugfix root cause : `.env.docker` avait encore `WEATHER_API_URL` pointant Open-Meteo → 500 systématique
- `iot_service/index.js` : réécriture — registry capteurs (cache 5min), extraction valeur par type (NPK/VENT/HTA = JSON), forwarding HTTP
- `validation.js` : `typeCapteur` aligné sur les 6 valeurs enum Prisma réelles (était : anciens types legacy)
- `store.ts` : `Capteur.type` aligné sur les 6 valeurs Prisma — supprime erreurs TS des mocks capteurs
- Dashboard : température sans `Math.round` (26.2°C au lieu de 26°C) + précipitations (`rain_level`) + luminosité (lux)
- Onglet météo : mêmes champs précipitations + luminosité ajoutés — grille détails 4 → 6 cartes
- Mocks visiteur : `weatherCurrent` inclut `rain_level`, `luminosity`, `station` · prévisions sur 4 horizons `horizon_heures`
- ✅ Pushé : `fablab-alt/AGROSMART` — commits `c457805` (dashboard) et `c5ee402` (meteo tab + store.ts)

---

### 2026-05-04 — Fixes : recommandations, login, GPS, MySQL orphelin

**Fichiers principaux :** `authService.js` · `register/page.tsx` · `recommandations/page.tsx` · `lib/api.ts` · `prisma/schema.prisma`
**État final :** Fonctionnel

- Container MySQL orphelin (port 3306) supprimé : `docker stop && docker rm && docker volume rm`
- `recommandations/page.tsx` : helpers `normalizeCategorie/Priorite/Statut` pour tolérer les shapes backend et mock (casse, int vs string)
- Décision : helpers `normalize*` dans la page (pas dans `api.ts`) — spécifiques au flux recommandations
- `authService.js` : trim + lowercase défensif sur email/password côté **backend** (protège tous les clients web/mobile/futurs)
- Schéma Prisma : `User.latitude` (Decimal 10,8) + `User.longitude` (Decimal 11,8) — `db push` appliqué
- `/regions` rendu public (sans `authenticate`) — donnée de référence nécessaire à l'inscription
- GPS registration : heuristique haversine côté frontend avec centres hardcodés — évite API géocodage externe
- `register/page.tsx` : chargement dynamique des régions au mount + fallback statique si réseau KO
- ✅ E2E : login avec espaces/majuscules → 200 · register avec GPS → coords en BDD

---

### 2026-05-03 — Forum complet + Réseau social + Marketplace location

**Fichiers principaux :** `prisma/schema.prisma` · `communauteController.js` · `friendshipsController.js` · `mobile/features/friendships/` · `frontend/app/(dashboard)/amis/page.tsx`
**État final :** Fonctionnel

- Prisma : ajout `Friendship` + `FriendshipStatus`, `ForumPostLike`, `ForumReponseUpvote`, `ForumPost.likes/tags`, `ForumReponse.isActive/updatedAt`
- Workaround : colonne `updated_at NOT NULL` sur table existante → `ALTER TABLE` SQL manuel avant `prisma db push`
- Décision : tables de jointure `forum_post_likes/forum_reponse_upvotes` + compteur cache sur parent (transaction Prisma) — unicité garantie + lecture rapide
- Décision : `Friendship` avec `requesterId/addresseeId` — si REJECTED, `update` au lieu d'insert (évite doublons)
- Décision : soft-delete posts/réponses (`isActive`) — cohérent avec le reste du projet
- Page `/amis` : 4 onglets (amis / reçues / envoyées / suggestions) + toutes les actions
- Mobile feature `friendships` : Clean Architecture complète (entity → datasource Dio → repository → BLoC → page 4 tabs)
- Mobile : utilise `sl<ApiClient>().dio` (intercepteurs et base URL déjà configurés)
- Marketplace location : champs `typeOffre/prixLocationJour/caution` exposés web + mobile (backend déjà supporté)
- ✅ E2E BDD réelle : friendships · forum likes/upvotes · marketplace location

---

### 2026-05-02 — Push GitHub initial

**Fichiers principaux :** `.gitignore` · `README.md` · `.env.docker.example`
**État final :** Fonctionnel

- `.gitignore` : `*.md` + `!/README.md` (aucun .md sauf README), `.env*`, flutter generated, doublons macOS `* 2.*`
- Force push (écrasement historique distant) — choix utilisateur
- Workaround HTTP 408 : `git config http.version HTTP/1.1 && git push --no-thin`
- Repo : `https://github.com/fablab-alt/AGROSMART`

---

### 2026-05-01 — Mode Visiteur + Docker

**Fichiers principaux :** `lib/store.ts` · `lib/api.ts` · `lib/mocks/index.ts` · `docker-compose.dev.yml` · `next.config.mjs`
**État final :** Fonctionnel

- Décision : `visitorMode` non persisté dans Zustand (`partialize` exclusion) — F5 = retour /login voulu
- `visitorMockAdapter` axios court-circuite avant tout appel HTTP — 0 requête réseau réelle en mode démo
- Dispatcher `lib/mocks/index.ts` : table `{p: RegExp, m: string, h: handler}[]`, 60+ routes couvertes
- Mutations (POST/PUT/PATCH/DELETE) → succès simulé + toast "Mode démo"
- Docker dev : MySQL:3307 · backend:3600 · frontend:3603, healthchecks, dépendances ordonnées
- `entrypoint.prod.sh` : wait MySQL (30×5s) → `prisma migrate deploy` → seed conditionnel → `node src/server.js`
- Décision : `output: 'standalone'` dans `next.config.mjs` pour image Docker frontend minimale
