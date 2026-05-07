# Commandes du projet AgroSmart

Ce document centralise les commandes pour lancer et maintenir tous les services: Backend, Frontend, Mobile, IoT et IA.

## 1) Prérequis

- Node.js 18+ (recommandé: 22)
- npm
- Flutter SDK
- JDK 17 (mobile Android)
- Python 3.10+ (service IA)
- Android SDK / ADB (pour émulateur)

## 2) Installation des dépendances

Depuis la racine du projet:

```bash
npm run install:all
```

Installation ciblée:

```bash
npm run install:backend
npm run install:frontend
npm run install:iot
npm run install:ai
```

## 3) Lancement en développement

> **⚠️ IMPORTANT — À lire avant de lancer quoi que ce soit**
>
> - **Ne jamais exécuter `npm run build` pour développer.** `npm run build` est un build de production: il compile toutes les pages Next.js et consomme énormément de RAM/CPU. Il ne sert qu'avant un déploiement (`npm start` ou PM2).
> - **Pour développer, utiliser uniquement `npm run dev`** (mode hot-reload, rapide, économe en RAM).
> - Si VS Code/votre Mac plante avec le frontend, c'est probablement que vous avez lancé `npm run build` par erreur.

---

### Option A — Tout lancer en une seule commande (recommandé)

**Depuis la racine du projet** (une seule fois, dans un seul terminal) :

```bash
# Lance Backend (3600) + Frontend (3601) + IoT (4000) + AI (5001) + Prisma Studio (5555)
npm run dev
```

L'orchestrateur démarre les services dans le bon ordre, attend que le backend soit disponible, puis lance le frontend et les services optionnels en parallèle.

Pour **exclure les services optionnels** si MQTT/TF ne sont pas installés :

```bash
npm run dev -- --no-iot --no-ai --no-studio
```

Pour lancer **uniquement le backend** :

```bash
npm run dev -- --backend
```

> Arrêter tous les services : **Ctrl+C** dans le terminal.

---

### Option B — Service par service (si l'option A pose problème)

Ouvrir **un terminal séparé par service** :

| Terminal | Dossier | Commande |
|---|---|---|
| 1 — Backend | racine | `npm run dev:backend` |
| 2 — Frontend | racine | `npm run dev:frontend` |
| 3 — IoT | racine | `npm run dev:iot` *(optionnel)* |
| 4 — AI | racine | `npm run dev:ai` *(optionnel)* |
| 5 — Studio | racine | `npm run db:studio` *(optionnel)* |

Toujours démarrer le **backend en premier** (les autres services en dépendent).

---

### Option C — Lancer le mobile Flutter (terminal séparé)

```bash
cd mobile
export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
flutter run -d emulator-5554
```

> Important: éviter de lancer plusieurs backends en parallèle (`npm run dev -- --backend` + `cd backend && npm run dev`) sinon erreur `EADDRINUSE` sur le port 3600.

---

### Si un port est déjà occupé

```bash
# Identifier le processus occupant un port (ex: 3600)
lsof -nP -iTCP:3600 -sTCP:LISTEN
kill -9 <PID>

# Idem pour le frontend (port 3603)
lsof -nP -iTCP:3603 -sTCP:LISTEN
kill -9 <PID>
```

### Limite mémoire (déjà configurée automatiquement)

Les scripts `dev` et `build` du frontend incluent une limite mémoire Node.js :
- `dev` : max **1.5 Go** de RAM
- `build` : max **2 Go** de RAM

Si votre machine a moins de 8 Go de RAM, lancer les services **un par un** via l'Option B plutôt que l'Option A.

## 4) Santé des services

```bash
npm run health
```

Endpoints health:

- Backend: <http://localhost:3600/health>
- IoT: <http://localhost:4000/health>
- IA: <http://localhost:5001/health>

## 5) Base de données (backend / Prisma)

```bash
npm run db:migrate
npm run db:migrate:dev
npm run db:push
npm run db:seed
npm run db:studio
npm run db:reset
```

### Gérer la base de données en ligne (Prisma Studio)

Prisma Studio est une interface web intégrée au projet pour **consulter, filtrer, créer, modifier et supprimer** des données dans la base Hostinger — sans installer aucun outil externe.

```bash
# Depuis la racine du projet
npm run db:studio

# Ou directement depuis backend/
cd backend && npx prisma studio
```

S'ouvre automatiquement sur **<http://localhost:5555>**.

**Ce que vous pouvez faire :**

- Parcourir les 61 tables (users, parcelles, mesures, alertes, marketplace…)
- Filtrer, trier et rechercher des enregistrements
- Créer / modifier / supprimer des lignes directement
- Voir les relations entre tables (clic sur un record lié)

> ⚠️ Prisma Studio modifie directement la base de **production** (Hostinger). Faire attention avant de supprimer des données.

**Accès alternatif (client MySQL externe) — si vous voulez TablePlus, DBeaver ou MySQL Workbench :**

| Paramètre | Valeur |
|-----------|--------|
| Hôte | `srv1579.hstgr.io` |
| Port | `3306` |
| Base | `u705315732_agrosmart` |
| Utilisateur | `u705315752_davis` |
| Mot de passe | voir `backend/.env` → `DB_PASSWORD` |
| SSL | Non requis pour connexion locale |

## 6) Frontend

> **Ne pas confondre `build` (production) et `dev` (développement).**

### Développement (hot-reload, usage courant)

```bash
# Depuis la racine — lance le frontend seul
npm run dev:frontend

# Ou depuis le dossier frontend/
cd frontend && npm run dev
```

### Build de production (uniquement pour déployer)

```bash
# Depuis la racine
npm run build
# ou
npm run build:frontend

# Puis lancer la version de production
cd frontend && npm run start
```

## 7) Mobile Flutter

Depuis `mobile/`:

```bash
flutter pub get
flutter run -d emulator-5554
```

### Important Android (Java)

Le projet est configuré pour Java 17.

```bash
export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
```

### Si erreur ADB / stockage insuffisant

Nettoyage rapide:

```bash
/Users/amalamanemmanueljeandavid/Library/Android/sdk/platform-tools/adb shell pm trim-caches 2G
/Users/amalamanemmanueljeandavid/Library/Android/sdk/platform-tools/adb shell pm clear com.agrismart.mobile
```

Nettoyage complet (recommandé si l'erreur persiste):

```bash
ADB=/Users/amalamanemmanueljeandavid/Library/Android/sdk/platform-tools/adb
$ADB uninstall com.example.mobile || true
$ADB uninstall com.agrosmart.agrosmart || true
$ADB uninstall com.agrismart.mobile || true
$ADB shell pm trim-caches 4G
$ADB shell "rm -rf /data/local/tmp/*"
$ADB shell "rm -rf /sdcard/Download/* /sdcard/Android/data/*/cache/* /sdcard/Android/media/*"
$ADB shell "df -h /data"
```

Vérifier que l'émulateur voit bien le backend:

```bash
ADB=/Users/amalamanemmanueljeandavid/Library/Android/sdk/platform-tools/adb
$ADB shell "toybox nc -z 10.0.2.2 3600 && echo ok"
```

Note: les messages `"bci"/"bm"/"ff" untranslated` ne bloquent pas le lancement de l'app, ce sont des avertissements de traduction.

## 8) Production (PM2)

```bash
npm start
npm run status
npm run logs
npm run restart
npm run stop
```

Equivalent direct PM2:

```bash
pm2 start ecosystem.config.js
pm2 status
pm2 logs
pm2 restart ecosystem.config.js
pm2 stop ecosystem.config.js
```

## 9) URLs utiles

- API Backend: <http://localhost:3600>
- Swagger/API docs: <http://localhost:3600/api-docs>
- Frontend: <http://localhost:3601>
- IoT: <http://localhost:4000>
- IA: <http://localhost:5001>
- **Prisma Studio**: <http://localhost:5555>

## 10) Cause de l'erreur "connexion serveur" mobile et correction

- Cause fréquente: l'app mobile pointait vers une IP locale machine non stable.
- Correction appliquée: host API de dev mobile par défaut = `10.0.2.2` (émulateur Android -> localhost du Mac).
- Précondition: backend démarré sur le port 3600.

## 11) Diagnostic rapide (copier-coller)

```bash
# Backend up ?
curl -s -m 5 http://localhost:3600/health

# Port backend libre/occupé ?
lsof -nP -iTCP:3600 -sTCP:LISTEN || echo "port 3600 free"

# Émulateur connecté ?
/Users/amalamanemmanueljeandavid/Library/Android/sdk/platform-tools/adb devices

# Espace disque émulateur ?
/Users/amalamanemmanueljeandavid/Library/Android/sdk/platform-tools/adb shell "df -h /data"
```
