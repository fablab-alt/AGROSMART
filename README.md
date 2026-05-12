# AgroSmart CI

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-22.x-green.svg)](https://nodejs.org/)
[![Next.js](https://img.shields.io/badge/Next.js-16.x-black.svg)](https://nextjs.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B.svg)](https://flutter.dev/)

Plateforme agricole intelligente pour la Côte d'Ivoire intégrant IoT, IA et analyse prédictive pour optimiser la production agricole.

**Domaine de production** : `agrosmart.voisilab.online`

---

## Vue d'ensemble

AgroSmart CI accompagne les producteurs, agronomes, acheteurs et coopératives ivoiriens dans la gestion de leurs exploitations grâce à :

- **Suivi temps réel des parcelles et capteurs IoT** (humidité, température, NPK, UV, etc.)
- **Recommandations IA personnalisées** (irrigation, fertilisation, traitement)
- **Diagnostic de maladies** par photo (TensorFlow)
- **Marketplace** : achat / vente / location de matériel agricole
- **Forum communautaire** avec likes, réponses et marquage de solution
- **Réseau social** : demandes d'amitié, suggestions par région
- **Météo** intégrée via la plateforme IoT [meteo.voisilab.online](https://meteo.voisilab.online) (capteurs physiques déployés en CI, prévisions IA à 4 horizons)
- **Mode visiteur** : exploration complète sans inscription, avec données mockées
- **Multi-langue** : Français, Baoulé, Malinké, Senoufo, Fulfulde, Bambara

---

## Architecture

```
Internet (HTTPS via Let's Encrypt)
    ↓
Traefik / Nginx (reverse proxy)
    ├─ agrosmart.voisilab.online      → Frontend Next.js  :3603
    ├─ api.agrosmart.voisilab.online  → Backend Node.js   :3600
    ├─ ai.agrosmart.voisilab.online   → AI Service Flask  :5001 (optionnel)
    └─ iot.agrosmart.voisilab.online  → IoT Service MQTT  :4000 (optionnel)
    ↓
MySQL 8.x
```

---

## Stack technique

| Composant | Technologie |
|-----------|-------------|
| **Backend** | Node.js 22 · Express 5 · Prisma 6 · MySQL 8 · Socket.IO · JWT |
| **Frontend** | Next.js 16 · React 19 · TypeScript · Tailwind CSS 4 · Zustand · Recharts |
| **Mobile** | Flutter 3.10+ · BLoC · Dio · Isar · go_router |
| **AI Service** | Python 3.11 · Flask · TensorFlow 2.20 · Gunicorn (optionnel) |
| **IoT Service** | Node.js · MQTT (optionnel) |
| **Infra** | Docker (multi-stage) · PM2 · Nginx · Let's Encrypt |

---

## Démarrage rapide (Docker)

```bash
# 1. Copier le template d'environnement
cp .env.docker.example .env.docker

# 2. Éditer .env.docker (mots de passe MySQL, JWT secrets, etc.)

# 3. Démarrer toute la stack
docker compose -f docker-compose.dev.yml --env-file .env.docker up --build -d
```

**Accès** :
- Frontend : http://localhost:3603
- Backend  : http://localhost:3600/api/v1
- MySQL    : localhost:3307 (port décalé pour éviter les conflits)

L'`entrypoint.prod.sh` du backend gère automatiquement :
1. Attente que MySQL soit prêt
2. Application des migrations Prisma
3. Seed initial si la base est vide

```bash
# Logs en live
docker compose -f docker-compose.dev.yml logs -f

# Arrêt
docker compose -f docker-compose.dev.yml down
```

---

## Démarrage local (sans Docker)

### Prérequis
- Node.js 22+
- MySQL 8+ accessible
- Python 3.11+ (uniquement pour AI Service, optionnel)
- Flutter 3.10+ (uniquement pour mobile)

### Installation

```bash
# Installer toutes les dépendances JS
node scripts/install-all.js

# Configurer .env (copier .env.example puis remplir)
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# Migrations Prisma
cd backend && npx prisma migrate deploy && cd ..

# Démarrer tout
node scripts/dev.js
```

---

## Fonctionnalités principales

### Mode Visiteur
Bouton « Mode démo » sur la landing page. Permet d'explorer l'intégralité de l'application avec des données mockées réalistes (60+ routes API interceptées côté client). Aucun appel réseau réel n'est fait au backend en mode visiteur.

### Forum communautaire
- Création / édition / suppression de posts (auteur ou admin)
- Réponses imbriquées avec marquage « solution »
- **Likes uniques par utilisateur** sur les posts (table `forum_post_likes`)
- **Upvotes uniques** sur les réponses (table `forum_reponse_upvotes`)
- Catégories dynamiques avec comptage
- Leaderboard et stats

### Réseau social
- Envoi de demandes d'amitié
- Acceptation / refus / annulation
- Liste d'amis confirmés
- Suggestions automatiques par région
- Statut d'amitié exposé pour affichage de bouton contextuel

### Marketplace
- Vente de produits (semences, engrais, récoltes, etc.)
- **Location de matériel** : `typeOffre`, `prixLocationJour`, `dureeMinLocation`, `caution`, `etat`
- Commandes, favoris, stats vendeur
- Upload jusqu'à 5 images par produit

### Inscription avec GPS
Le formulaire d'inscription propose un bouton « Ma position » qui :
- Demande la géolocalisation HTML5
- Sélectionne automatiquement la région la plus proche (heuristique haversine sur les chefs-lieux ivoiriens)
- Enregistre `latitude` et `longitude` dans le profil utilisateur

---

## Structure du repo

```
.
├── backend/              Express + Prisma + MySQL
│   ├── src/
│   │   ├── controllers/  35+ contrôleurs (auth, parcelles, communauté, friendships...)
│   │   ├── routes/       39 fichiers de routes
│   │   └── services/     15 services métier
│   ├── prisma/           Schéma BDD
│   └── scripts/          Seeders + outils d'audit
├── frontend/             Next.js 16 (App Router)
│   ├── src/app/
│   │   ├── (auth)/       login, register (avec GPS), forgot-password
│   │   ├── (dashboard)/  27 pages : dashboard, parcelles, capteurs, forum, /amis, marketplace...
│   │   └── (admin)/      10+ pages d'administration
│   └── src/lib/mocks/    Couche mock complète pour mode visiteur
├── mobile/               Flutter (15+ features Clean Architecture)
├── ai_service/           Flask + TensorFlow (optionnel)
├── iot_service/          MQTT broker (optionnel)
├── docker-compose.yml       Production (Traefik)
├── docker-compose.dev.yml   Développement local
└── Dockerfile               Multi-stage : backend-runtime + frontend-runtime (standalone)
```

---

## Variables d'environnement essentielles

```bash
# Base
NODE_ENV=production
TZ=Africa/Abidjan

# Base de données
DATABASE_URL="mysql://user:pass@host:port/db?connection_limit=10"

# JWT (min 64 caractères)
JWT_SECRET=...
JWT_REFRESH_SECRET=...

# CORS
ALLOWED_ORIGINS=https://agrosmart.voisilab.online

# Frontend (variables publiques Next.js)
NEXT_PUBLIC_API_URL=https://api.agrosmart.voisilab.online/api/v1
NEXT_PUBLIC_SOCKET_URL=https://api.agrosmart.voisilab.online

# Météo voisilab IoT (pas de clé nécessaire)
WEATHER_API_URL=https://meteo.voisilab.online/api

# SMS / Email — voir .env.docker.example pour la liste complète
```

Référence complète des variables dans `.env.docker.example`.

---

## Licence

MIT — voir le fichier `LICENSE` à la racine.
