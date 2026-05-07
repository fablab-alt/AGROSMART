# AgroSmart CI - Plateforme Agricole Intelligente

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-22.x-green.svg)](https://nodejs.org/)
[![Next.js](https://img.shields.io/badge/Next.js-16.x-black.svg)](https://nextjs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev/)

AgroSmart CI est une plateforme agricole intelligente pour la Cote d'Ivoire,
integrant IoT, Intelligence Artificielle et analyses predictives pour optimiser
la production agricole.

## Fonctionnalites

- Surveillance des parcelles en temps reel via capteurs IoT
- Recommandations basees sur l'IA (diagnostic maladies, irrigation)
- Gestion des cultures, rendements et recoltes
- Marketplace agricole (achat/vente de produits)
- Cooperatives et adhesions
- Dashboard analytique avec statistiques et ROI
- Applications web (Next.js) et mobile (Flutter)

## Architecture

```text
Nginx (80/443)
  +-- Frontend Next.js :3603
  +-- Backend Node.js  :3600
  +-- AI Service Flask :5001 (optionnel)
  +-- IoT Service      :4000 (optionnel)
  +-- MySQL 8.x (Hostinger distant)
```

Deploiement : **PM2** gere les processus, **Nginx** en reverse proxy.

## Technologies

- **Backend** : Node.js 22, Express 5.2, Prisma 6.9, Socket.IO, JWT, Winston
- **Frontend** : Next.js 16, React 19, Tailwind CSS 4, Zustand, Recharts
- **Mobile** : Flutter 3.10+, Dart, flutter\_bloc, Dio
- **AI/ML** : Python, TensorFlow 2.x, Flask
- **Infra** : PM2, Nginx, Certbot, Hostinger VPS

## Prerequis

- Node.js v22.x, npm v10.x
- Python v3.11+ (service AI, optionnel)
- Flutter v3.10+ (app mobile)
- Git v2.x

## Installation

### Backend

```bash
cd backend
npm install
cp .env.example .env
npx prisma generate
npx prisma migrate deploy
node scripts/seed_admin.js
npm run dev
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

### Mobile

```bash
cd mobile
flutter pub get
flutter run
```

## Configuration

Voir [ENV\_VARIABLES.md](./ENV_VARIABLES.md) pour toutes les variables d'environnement.

Variables essentielles backend :

- `DATABASE_URL` : connexion MySQL
- `JWT_SECRET` / `JWT_REFRESH_SECRET` : secrets JWT
- `ALLOWED_ORIGINS` : origins CORS
- `PORT` : 3600

## Utilisation

- Backend : `cd backend && npm run dev` (port 3600)
- Frontend : `cd frontend && npm run dev` (port 3603)
- Mobile : `cd mobile && flutter run`
- API Docs : `http://localhost:3600/api/docs`
- Health : `http://localhost:3600/health`

Compte admin : `admin@agrosmart.ci` / `ChangeMe@2024!`

## API Endpoints

- `POST /api/v1/auth/register` - Inscription
- `POST /api/v1/auth/login` - Connexion
- `POST /api/v1/auth/refresh` - Refresh token
- `GET /api/v1/parcelles` - Parcelles
- `GET /api/v1/cultures` - Cultures
- `GET /api/v1/capteurs` - Capteurs IoT
- `GET /api/v1/mesures` - Mesures
- `POST /api/v1/diagnostics` - Diagnostic IA
- `GET /api/v1/marketplace/produits` - Marketplace
- `GET /api/v1/dashboard/stats` - Dashboard
- `GET /api/v1/alertes` - Alertes
- `GET /api/v1/recommandations` - Recommandations
- `GET /api/v1/formations` - Formations

Auth requise : `Authorization: Bearer TOKEN`

## Deploiement

Voir [DEPLOY.md](./DEPLOY.md) pour le guide complet VPS Hostinger + Nginx + PM2.

```bash
pm2 start ecosystem.config.js
pm2 save && pm2 startup
```

## Structure

```text
backend/          API Node.js + Express + Prisma
frontend/         App Web Next.js
mobile/           App Mobile Flutter
ai_service/       Service IA Python (optionnel)
iot_service/      Service IoT (optionnel)
nginx/            Config Nginx
ecosystem.config.js   Config PM2
DEPLOY.md         Guide deploiement
ENV_VARIABLES.md  Variables d'environnement
```

## Securite

- Ne jamais commiter de fichiers .env
- Hook pre-commit pour detection de secrets
- Variables d'environnement pour tous les secrets
- Changer les mots de passe par defaut en production

## Licence

Licence MIT.
