# 🐳 Docker Configuration Status Report

**Date**: 7 mai 2026  
**Status**: ⚠️ Partiellement Opérationnel

## ✅ Réussi

### Frontend Web
- ✅ **Container lancé et opérationnel**
  - Port: 3603
  - URL: http://localhost:3603
  - Status: Running (Up 2+ minutes)
  - Application Next.js 16.2.1 démarrée avec succès

### Infrastructure Docker
- ✅ Réseau `traefik-network` créé
- ✅ Réseau `app-network` créé
- ✅ Images Docker construites:
  - `agrosmartcv-backend:latest` (1.7GB)
  - `agrosmartcv-frontend:latest` (2.11GB)
- ✅ Docker Compose configuration validée

## ⚠️ Problème identifié: Backend

### Problème
Le container backend n'arrive pas à se connecter à la base de données VPS sur `srv1579.hstgr.io:3306`

**Logs du backend**:
```
Error: Can't reach database server at `srv1579.hstgr.io:3306`
Please make sure your database server is running at `srv1579.hstgr.io:3306`
```

### Diagnostic effectué
✓ Connectivité locale vers srv1579.hstgr.io:3306 → **OK**  
✗ Connexion Prisma depuis container → **ÉCHOUÉ**

### Causes Possibles
1. **Firewall/IP Whitelist**: La VPS peut bloquer les connexions de containers Docker
2. **DNS du conteneur**: Le conteneur n'arrive peut-être pas à résoudre le hostname
3. **Authentification**: Vérification des credentials (user/password)
4. **Isolation réseau**: Le conteneur peut avoir des restrictions de réseau

## 🔧 Solutions Proposées

### Solution 1: Utiliser MySQL Local pour Développement (Recommandé)
```bash
# Installer MySQL via Homebrew (Mac)
brew install mysql@8.0

# Lancer MySQL
brew services start mysql@8.0

# Créer la base de données
mysql -u root -e "
  CREATE DATABASE IF NOT EXISTS u705315732_agrosmart2;
  CREATE USER 'u705315732_davis2'@'localhost' IDENTIFIED BY '8lqkTcI4Sd\$';
  GRANT ALL PRIVILEGES ON u705315732_agrosmart2.* TO 'u705315732_davis2'@'localhost';
  FLUSH PRIVILEGES;
"

# Mettre à jour .env
DATABASE_URL=mysql://u705315732_davis2:8lqkTcI4Sd%24@localhost:3306/u705315732_agrosmart2
```

### Solution 2: Utiliser conteneur MySQL Docker
```bash
# Lancer MySQL en container
docker run -d \
  --name mysql-agrosmart \
  -e MYSQL_ROOT_PASSWORD=root_password \
  -e MYSQL_DATABASE=u705315732_agrosmart2 \
  -e MYSQL_USER=u705315732_davis2 \
  -e MYSQL_PASSWORD='8lqkTcI4Sd$' \
  -p 3306:3306 \
  --network app-network \
  mysql:8.0

# Ajouter au docker-compose.yml pour le déploiement complet
```

### Solution 3: Autoriser la VPS à accepter les connections Docker
```bash
# Sur le VPS, vérifier les restrictions d'accès MySQL:
mysql -u root -p -e "SELECT Host FROM mysql.user WHERE User='u705315732_davis2';"

# Ajouter l'accès Docker (remplacer par l'IP Docker Gateway):
mysql -u root -p -e "
  GRANT ALL PRIVILEGES ON u705315732_agrosmart2.* 
  TO 'u705315732_davis2'@'%' 
  IDENTIFIED BY '8lqkTcI4Sd\$';
  FLUSH PRIVILEGES;
"
```

### Solution 4: Désactiver temporairement la connexion DB au démarrage
Modifier `backend/src/server.js` pour continuer même sans DB:
```javascript
try {
    await prisma.$connect();
    logger.info('Prisma connected to MySQL successfully');
} catch (error) {
    logger.warn('Impossible de connecter Prisma, continuan tquand même...', { 
      error: error.message 
    });
}
```

## 🚀 Pour Relancer Les Containers

### Après avoir choisi une solution:

**Option A: MySQL Local**
```bash
# Créer DB locale, puis:
docker-compose up -d
```

**Option B: MySQL Docker**
```bash
# Ajouter service mysql au docker-compose.yml, puis:
docker-compose up -d
```

**Option C: Ignorer erreur DB**
```bash
# Modifier server.js pour ignorer erreur DB, puis:
docker-compose up -d
```

## 📊 État actuel des containers

```bash
docker-compose ps

# Output:
NAME                IMAGE              STATUS
agrosmart-frontend  agrosmartcv-...   Up 2 minutes ✅
agrosmart-backend   agrosmartcv-...   Stopped ⏹️
```

## 🧪 Tester après correction

### Frontend (actuellement actif)
```bash
open http://localhost:3603
# ou
curl http://localhost:3603
```

### Backend (une fois fixé)
```bash
curl http://localhost:3600/api/v1/health
```

## 📝 Configuration Actuelle

**Fichiers modifiés**:
- `.env` - Configuration de connexion BD
- `docker-compose.yml` - Orchestration des containers
- Images Docker - Reconstruites avec config prod

**Réseau Docker**:
- `traefik-network` - Réseau externe (Traefik reverse proxy)
- `app-network` - Réseau interne (communication inter-services)

**Ports**:
- 3600: Backend API
- 3603: Frontend Web
- 3306: MySQL (externe, VPS)

## ✅ Prochaines Étapes

1. **Choisir une solution** pour la base de données
2. **Implémenter la solution** (MySQL local recommandé pour test)
3. **Redémarrer les containers**: `docker-compose up -d`
4. **Vérifier les logs**: `docker-compose logs backend`
5. **Tester l'API**: `curl http://localhost:3600/api/v1/health`

## 📱 Pour l'Application Mobile

La configuration est prête:
- **API Backend**: Sera disponible sur http://localhost:3600/api/v1 (une fois fixé)
- **Frontend Web**: http://localhost:3603 (✅ Actuel)
- **Configuration des services**: À confirmer après fix du backend

---

**Recommandation**: Utilisez Solution 1 (MySQL Local) pour développement rapide.

Besoin d'aide? Contactez l'équipe DevOps.
