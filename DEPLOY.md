# 🚀 Guide de Déploiement — AgroSmart CI
## VPS Hostinger · Nginx + PM2 · Sans Docker

---

## 📋 Table des matières

- [Architecture de production](#-architecture-de-production)
- [Prérequis VPS](#-prérequis-vps)
- [Étape 1 — Préparation du VPS](#étape-1--préparation-du-vps)
- [Étape 2 — Récupérer le code](#étape-2--récupérer-le-code)
- [Étape 3 — Backend (Node.js + Prisma)](#étape-3--backend-nodejs--prisma)
- [Étape 4 — Frontend (Next.js)](#étape-4--frontend-nextjs)
- [Étape 5 — AI Service (Python + Gunicorn)](#étape-5--ai-service-python--gunicorn)
- [Étape 6 — IoT Service (Node.js + MQTT)](#étape-6--iot-service-nodejs--mqtt)
- [Étape 7 — PM2 (Gestionnaire de processus)](#étape-7--pm2-gestionnaire-de-processus)
- [Étape 8 — Nginx (Reverse proxy par service)](#étape-8--nginx-reverse-proxy-par-service)
- [Étape 9 — SSL / HTTPS (Let's Encrypt)](#étape-9--ssl--https-lets-encrypt)
- [Étape 10 — Vérification finale](#étape-10--vérification-finale)
- [Commandes de maintenance](#-commandes-de-maintenance)
- [Mises à jour du code](#-mises-à-jour-du-code)
- [Dépannage](#-dépannage)

> 📄 **Variables d'environnement** : voir [`ENV_VARIABLES.md`](./ENV_VARIABLES.md) pour la liste
> complète de toutes les variables à configurer avant le déploiement.

---

## 🏗 Architecture de production

```
Internet
   │
   ▼
┌─────────────────────────────────────────────┐
│         Nginx (port 80 / 443)               │
│                                             │
│  agrosmart.ci ──────► Frontend   :3601      │
│  api.agrosmart.ci ──► Backend    :3600      │
│  ai.agrosmart.ci ───► AI Service :5001      │
│  iot.agrosmart.ci ──► IoT Service:4000      │
└─────────────────────────────────────────────┘
         │               │           │
         ▼               ▼           ▼
  ┌────────────┐  ┌────────────┐  ┌────────────┐
  │  PM2       │  │  PM2       │  │  PM2       │
  │  backend   │  │  frontend  │  │  ai/iot    │
  │  :3600     │  │  :3601     │  │  :5001     │
  └─────┬──────┘  └────────────┘  └────────────┘
        │
        ▼
  MySQL Hostinger
  (voir ENV_VARIABLES.md pour les credentials)
```

> **Note** : Si vous n'avez pas de nom de domaine, tous les services peuvent
> être servis depuis la même IP avec des `location` blocks différents dans un
> seul Nginx. Les deux approches sont documentées ci-dessous.

---

## 💻 Prérequis VPS

- **OS** : Ubuntu 22.04 LTS (recommandé)
- **RAM** : 4 GB minimum (8 GB recommandé)
- **CPU** : 2 vCPU minimum
- **Ports ouverts** : 22 (SSH), 80 (HTTP), 443 (HTTPS)
- **Accès** : SSH root ou utilisateur sudo

---

## Étape 1 — Préparation du VPS

### 1.1 Connexion et mise à jour

```bash
ssh root@VOTRE_IP_VPS

# Mettre à jour le système
apt update && apt upgrade -y
apt install -y curl git wget nano build-essential
```

### 1.2 Installer Node.js 22

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

# Vérifier
node -v   # doit afficher v22.x.x
npm -v    # doit afficher 10.x.x
```

### 1.3 Installer Python 3 + pip

```bash
apt install -y python3 python3-pip python3-venv python3-dev
python3 --version   # doit afficher 3.10+
```

### 1.4 Installer PM2 (gestionnaire de processus)

```bash
npm install -g pm2
pm2 --version
```

### 1.5 Installer Nginx

```bash
apt install -y nginx
systemctl start nginx
systemctl enable nginx
nginx -v
```

### 1.6 Configurer le pare-feu

```bash
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw enable
ufw status
```

### 1.7 (Optionnel) Créer un utilisateur dédié

```bash
adduser agrismart
usermod -aG sudo agrismart
su - agrismart
```

---

## Étape 2 — Récupérer le code

```bash
mkdir -p /var/www/agrosmart
cd /var/www

git clone https://github.com/davis48/agrosmart.git agrosmart
cd agrosmart

# Créer les dossiers de logs
mkdir -p logs/pm2 backend/uploads backend/logs
```

---

## Étape 3 — Backend (Node.js + Prisma)

### 3.1 Installer les dépendances

```bash
cd /var/www/agrosmart/backend
npm install --production
```

### 3.2 Configurer l'environnement

```bash
# Créer le .env depuis le template
cp .env.example .env
nano .env
```

> ⚠️ Remplir toutes les variables listées dans [`ENV_VARIABLES.md`](./ENV_VARIABLES.md).
> En particulier : `DB_HOST`, `DB_PASSWORD`, `DATABASE_URL`, `ALLOWED_ORIGINS`, `JWT_SECRET`.

### 3.3 Générer le client Prisma

```bash
cd /var/www/agrosmart/backend
npx prisma generate
```

### 3.4 Appliquer les migrations de base de données

```bash
npx prisma migrate deploy

# Vérifier que la connexion fonctionne
npx prisma db pull
```

### 3.5 (Optionnel) Seeder la base de données

```bash
# Créer le compte administrateur
node scripts/seed_admin.js

# OU seeder toutes les données de démonstration
npm run db:seed
```

### 3.6 Tester le backend en local

```bash
cd /var/www/agrosmart/backend
NODE_ENV=production node src/server.js &
sleep 3
curl http://localhost:3600/health
# Réponse attendue: {"status":"ok",...}
kill %1
```

---

## Étape 4 — Frontend (Next.js)

### 4.1 Installer les dépendances

```bash
cd /var/www/agrosmart/frontend
npm install
```

### 4.2 Configurer l'environnement

```bash
nano .env.local
```

```bash
# Si domaine configuré :
NEXT_PUBLIC_API_URL=https://api.votre-domaine.com/api/v1
NEXT_PUBLIC_SOCKET_URL=https://api.votre-domaine.com

# Si IP uniquement :
NEXT_PUBLIC_API_URL=http://VOTRE_IP_VPS/api/v1
NEXT_PUBLIC_SOCKET_URL=http://VOTRE_IP_VPS

NODE_ENV=production
```

### 4.3 Builder l'application

```bash
cd /var/www/agrosmart/frontend
npm run build
```

> ⏳ Le build peut prendre 2–5 minutes selon la machine.

---

## Étape 5 — AI Service (Python + Gunicorn)

### 5.1 Créer l'environnement virtuel

```bash
cd /var/www/agrosmart/ai_service
python3 -m venv .venv
source .venv/bin/activate
```

### 5.2 Installer les dépendances

```bash
pip install --upgrade pip
pip install -r requirements.txt
# gunicorn est inclus dans requirements.txt — pas besoin de 'pip install gunicorn'

# Tester
python app.py &
sleep 3
curl http://localhost:5001/health
# Réponse attendue: {"status":"healthy","tensorflow":"available",...}
kill %1

deactivate
```

> **Note** : Si TensorFlow n'est pas disponible (architecture ARM non compatibles, etc.),
> le service démarre quand même en **mode dégradé** — les endpoints `/predict/*` retournent
> `503 Unavailable` mais `/health` répond `200` normalement.

### 5.3 Vérifier les modèles IA

```bash
ls /var/www/agrosmart/ai_service/models/
```

> ⚠️ Si les modèles ne sont pas dans le repo (trop lourds pour Git),
> les transférer via SFTP depuis votre machine locale :
> ```bash
> scp -r ./ai_service/models/ root@VOTRE_IP:/var/www/agrosmart/ai_service/
> ```

---

## Étape 6 — IoT Service (Node.js + MQTT)

### 6.1 Installer les dépendances

```bash
cd /var/www/agrosmart/iot_service
npm install --production
```

### 6.2 Configurer l'environnement

```bash
cp .env.example .env 2>/dev/null || touch .env
nano .env
```

```bash
NODE_ENV=production
PORT=4000
MQTT_BROKER_URL=mqtt://127.0.0.1:1883
BACKEND_API_URL=http://127.0.0.1:3600
```

### 6.3 (Optionnel) Installer Mosquitto (broker MQTT)

```bash
apt install -y mosquitto mosquitto-clients
systemctl enable mosquitto
systemctl start mosquitto
mosquitto_pub -h localhost -t test -m "hello"
```

> **Note** : Si vous n'avez pas de capteurs IoT, ce service est optionnel.

---

## Étape 7 — PM2 (Gestionnaire de processus)

### 7.1 Vérifier le fichier ecosystem.config.js

```bash
cat /var/www/agrosmart/ecosystem.config.js
```

### 7.2 Démarrer les services

```bash
cd /var/www/agrosmart

# Minimum requis (Backend + Frontend)
pm2 start ecosystem.config.js --only agrismart-backend,agrismart-frontend

# OU tous les services
pm2 start ecosystem.config.js

# Vérifier l'état
pm2 status
```

Résultat attendu :

```
┌────┬───────────────────────┬─────────┬──────┬───────────┬──────────┐
│ id │ name                  │ mode    │ ↺    │ status    │ cpu      │
├────┼───────────────────────┼─────────┼──────┼───────────┼──────────┤
│ 0  │ agrismart-backend     │ cluster │ 0    │ online    │ 0%       │
│ 1  │ agrismart-frontend    │ fork    │ 0    │ online    │ 0%       │
│ 2  │ agrismart-ai          │ fork    │ 0    │ online    │ 0%       │
│ 3  │ agrismart-iot         │ fork    │ 0    │ online    │ 0%       │
└────┴───────────────────────┴─────────┴──────┴───────────┴──────────┘
```

### 7.3 Configurer le démarrage automatique

```bash
pm2 startup
# ⚠️ COPIER ET EXÉCUTER la commande affichée par PM2

pm2 save
```

### 7.4 Commandes PM2 essentielles

```bash
pm2 status                             # État de tous les processus
pm2 logs                               # Tous les logs en temps réel
pm2 logs agrismart-backend --lines 50  # Logs du backend
pm2 logs agrismart-frontend --lines 50 # Logs du frontend
pm2 restart agrismart-backend          # Redémarrer le backend
pm2 reload agrismart-backend           # Rechargement 0 downtime (cluster)
pm2 restart agrismart-frontend         # Redémarrer le frontend
pm2 stop agrismart-iot                 # Arrêter l'IoT service
pm2 monit                              # Dashboard monitoring temps réel
pm2 flush                              # Vider tous les logs
```

---

## Étape 8 — Nginx (Reverse proxy par service)

Choisir **Option A** (avec domaine) ou **Option B** (IP seule).

### Option A — Avec domaine (recommandé)

Un fichier de config Nginx dédié par service.

#### 8A.1 — Backend API (`api.votre-domaine.com`)

```bash
nano /etc/nginx/sites-available/agrosmart-backend
```

```nginx
server {
    listen 80;
    server_name api.votre-domaine.com;

    access_log /var/log/nginx/agrosmart-backend-access.log;
    error_log  /var/log/nginx/agrosmart-backend-error.log;

    client_max_body_size 50M;
    proxy_connect_timeout 60s;
    proxy_send_timeout    60s;
    proxy_read_timeout    60s;

    location / {
        proxy_pass         http://127.0.0.1:3600;
        proxy_http_version 1.1;
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /uploads/ {
        alias /var/www/agrosmart/backend/uploads/;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
}
```

#### 8A.2 — Frontend (`votre-domaine.com`)

```bash
nano /etc/nginx/sites-available/agrosmart-frontend
```

```nginx
server {
    listen 80;
    server_name votre-domaine.com www.votre-domaine.com;

    access_log /var/log/nginx/agrosmart-frontend-access.log;
    error_log  /var/log/nginx/agrosmart-frontend-error.log;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;

    location / {
        proxy_pass         http://127.0.0.1:3601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location /_next/static/ {
        proxy_pass http://127.0.0.1:3601;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

#### 8A.3 — AI Service (`ai.votre-domaine.com`) *(optionnel)*

```bash
nano /etc/nginx/sites-available/agrosmart-ai
```

```nginx
server {
    listen 80;
    server_name ai.votre-domaine.com;

    access_log /var/log/nginx/agrosmart-ai-access.log;
    error_log  /var/log/nginx/agrosmart-ai-error.log;

    client_max_body_size 20M;

    location / {
        proxy_pass         http://127.0.0.1:5001;
        proxy_http_version 1.1;
        proxy_set_header Host            $host;
        proxy_set_header X-Real-IP       $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 120s;
    }
}
```

#### 8A.4 — IoT Service (`iot.votre-domaine.com`) *(optionnel)*

```bash
nano /etc/nginx/sites-available/agrosmart-iot
```

```nginx
server {
    listen 80;
    server_name iot.votre-domaine.com;

    access_log /var/log/nginx/agrosmart-iot-access.log;
    error_log  /var/log/nginx/agrosmart-iot-error.log;

    location / {
        proxy_pass         http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Host            $host;
        proxy_set_header X-Real-IP       $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

#### 8A.5 — Activer les sites et recharger Nginx

```bash
ln -s /etc/nginx/sites-available/agrosmart-backend  /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/agrosmart-frontend /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/agrosmart-ai       /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/agrosmart-iot      /etc/nginx/sites-enabled/

rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl reload nginx
```

---

### Option B — Sans domaine (IP uniquement)

```bash
nano /etc/nginx/sites-available/agrosmart
```

```nginx
upstream agrosmart_backend  { server 127.0.0.1:3600; keepalive 32; }
upstream agrosmart_frontend { server 127.0.0.1:3601; keepalive 16; }
upstream agrosmart_ai       { server 127.0.0.1:5001; }
upstream agrosmart_iot      { server 127.0.0.1:4000; }

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    access_log /var/log/nginx/agrosmart-access.log;
    error_log  /var/log/nginx/agrosmart-error.log;

    client_max_body_size 50M;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Backend API
    location /api/ {
        proxy_pass         http://agrosmart_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 60s;
    }

    # WebSocket Socket.IO
    location /socket.io/ {
        proxy_pass         http://agrosmart_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }

    location /health {
        proxy_pass http://agrosmart_backend;
        proxy_set_header Host $host;
    }

    location /uploads/ {
        alias /var/www/agrosmart/backend/uploads/;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # AI Service
    location /ai/ {
        rewrite ^/ai/(.*) /$1 break;
        proxy_pass         http://agrosmart_ai;
        proxy_http_version 1.1;
        proxy_set_header Host            $host;
        proxy_set_header X-Real-IP       $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 120s;
        client_max_body_size 20M;
    }

    # IoT Service
    location /iot/ {
        rewrite ^/iot/(.*) /$1 break;
        proxy_pass         http://agrosmart_iot;
        proxy_http_version 1.1;
        proxy_set_header Host            $host;
        proxy_set_header X-Real-IP       $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Frontend Next.js (toujours EN DERNIER)
    location /_next/static/ {
        proxy_pass http://agrosmart_frontend;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location / {
        proxy_pass         http://agrosmart_frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
ln -s /etc/nginx/sites-available/agrosmart /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
```

---

## Étape 9 — SSL / HTTPS (Let's Encrypt)

> Nécessite un **nom de domaine** pointant vers l'IP du VPS.

```bash
apt install -y certbot python3-certbot-nginx

# Option A (sous-domaines)
certbot --nginx -d votre-domaine.com -d www.votre-domaine.com
certbot --nginx -d api.votre-domaine.com
certbot --nginx -d ai.votre-domaine.com
certbot --nginx -d iot.votre-domaine.com

# Option B (domaine unique)
certbot --nginx -d votre-domaine.com

# Renouvellement automatique (test)
certbot renew --dry-run
```

---

## Étape 10 — Vérification finale

```bash
# Backend direct
curl http://localhost:3600/health
# Attendu: {"status":"ok","timestamp":"...","uptime":...}

# Backend via Nginx
curl http://VOTRE_IP_VPS/health

# Frontend
curl -I http://localhost:3601
curl -I http://VOTRE_IP_VPS

# AI Service
curl http://localhost:5001/health

# PM2 status
pm2 status

# Test d'inscription complet
curl -X POST http://VOTRE_IP_VPS/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "telephone": "0700000001",
    "password": "Test@1234!",
    "nom": "Koné",
    "prenoms": "Amadou",
    "role": "PRODUCTEUR"
  }'
# Attendu: {"success":true,"token":"eyJ...","user":{...}}
```

---

## 🔧 Commandes de maintenance

### Logs

```bash
pm2 logs                                    # Tous
pm2 logs agrismart-backend  --lines 100     # Backend
pm2 logs agrismart-frontend --lines 100     # Frontend

tail -f /var/log/nginx/agrosmart-backend-access.log
tail -f /var/log/nginx/agrosmart-backend-error.log
```

### Redémarrage

```bash
pm2 reload agrismart-backend    # 0 downtime
pm2 restart agrismart-frontend
pm2 reload all

systemctl reload nginx
```

### Base de données

```bash
cd /var/www/agrosmart/backend

npx prisma db pull              # Tester la connexion
npx prisma migrate deploy       # Appliquer nouvelles migrations
npx prisma studio               # GUI sur port 5555

# Backup (depuis le serveur)
mysqldump -h DB_HOST -u DB_USER -p DB_NAME > backup_$(date +%Y%m%d_%H%M%S).sql
```

---

## 🔄 Mises à jour du code

```bash
cd /var/www/agrosmart
git pull origin main

# Backend
cd backend && npm install --production && npx prisma generate && npx prisma migrate deploy
cd .. && pm2 reload agrismart-backend

# Frontend (rebuild obligatoire)
cd frontend && npm install && npm run build
cd .. && pm2 restart agrismart-frontend

# IoT Service
cd iot_service && npm install --production
cd .. && pm2 restart agrismart-iot

# AI Service
cd ai_service && source .venv/bin/activate && pip install -r requirements.txt && deactivate
cd .. && pm2 restart agrismart-ai
```

---

## 🐛 Dépannage

### Backend ne démarre pas

```bash
pm2 logs agrismart-backend --lines 50 --err

# Test manuel
cd /var/www/agrosmart/backend
NODE_ENV=production node src/server.js
```

**Causes fréquentes :**
- `DATABASE_URL` mal formée (encoder `+` en `%2B`)
- Port 3600 déjà utilisé → `lsof -i :3600`
- `node_modules` manquant → `npm install --production`

### Frontend ne démarre pas

```bash
pm2 logs agrismart-frontend --lines 50 --err
```

**Cause fréquente :** Build manquant → `cd frontend && npm run build`

### Nginx retourne 502 Bad Gateway

```bash
pm2 status
ss -tlnp | grep -E '3600|3601|5001|4000'
curl http://127.0.0.1:3600/health
tail -50 /var/log/nginx/agrosmart-backend-error.log
```

### IoT Service ne démarre pas

```bash
pm2 logs agrismart-iot --lines 30 --err
```

### AI Service ne démarre pas

```bash
pm2 logs agrismart-ai --lines 30 --err

# Vérifier le venv
ls /var/www/agrosmart/ai_service/.venv/bin/gunicorn
# Si absent : cd ai_service && python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt && deactivate

# Tester manuellement
cd /var/www/agrosmart/ai_service
.venv/bin/gunicorn --workers 2 --bind 127.0.0.1:5001 --timeout 120 app:app
```

---

## 📌 Récapitulatif des ports

| Service          | Port local | Exposé via Nginx                      |
|------------------|------------|---------------------------------------|
| Backend API      | **3600**   | `/api/*`, `/socket.io/*`, `/health`   |
| Frontend Next.js | **3601**   | `/` (racine)                          |
| AI Service       | 5001       | `/ai/*` ou `ai.domaine.com`           |
| IoT Service      | 4000       | `/iot/*` ou `iot.domaine.com`         |
| MySQL Hostinger  | 3306       | Direct (pas via Nginx)                |

> **Prisma Studio** (port 5555) est un outil de développement uniquement — ne pas l'exposer en production.

---

## ⚠️ Sécurité

- Les fichiers `.env` et `.env.local` sont dans `.gitignore` → **jamais poussés sur Git**
- Ne jamais commiter les fichiers `.env` contenant de vraies credentials
- Voir [`ENV_VARIABLES.md`](./ENV_VARIABLES.md) pour la liste des variables à configurer
