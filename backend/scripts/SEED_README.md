# Script de Seed Complet - Agrosmart CI

## Description

Ce script remplit **TOUTES** les tables de la base de données avec des données réalistes pour permettre des tests complets de l'application mobile et web.

## Données Créées

### Données de Base
- ✅ **7 Régions** de Côte d'Ivoire (Abidjan, Yamoussoukro, Bouaké, Daloa, Korhogo, Man, San-Pédro)
- ✅ **5 Coopératives** agricoles
- ✅ **43 Utilisateurs** (1 Admin, 2 Agronomes, 2 Conseillers, 20 Producteurs, 10 Acheteurs, 5 Fournisseurs)

### Cultures et Maladies
- ✅ **10 Cultures** (Cacao, Café, Hévéa, Manioc, Igname, Maïs, Riz, Banane Plantain, Tomate, Piment)
- ✅ **8 Maladies** avec symptômes et traitements détaillés

### Parcelles et IoT
- ✅ **40-80 Parcelles** (2-4 par producteur)
- ✅ **28-56 Stations IoT** (70% des parcelles)
- ✅ **84-336 Capteurs** (3-6 par station)
- ✅ **11,760-70,560 Mesures** (14 jours d'historique, 6 mesures/jour/capteur)
- ✅ **60-140 Alertes** (3-7 par producteur)

### Productions
- ✅ **40-240 Plantations** (1-3 par parcelle)
- ✅ **24-144 Récoltes** (avec rendements réalistes)
- ✅ **40-140 Diagnostics** de maladies (2-5 par producteur)

### Marketplace
- ✅ **20 Produits** (récoltes, intrants, semences)
- ✅ **86-172 Commandes** (2-5 par acheteur)
- ✅ **60-120 Transactions** de paiement
- ✅ **43 Paniers** avec items
- ✅ **86-344 Favoris** (2-8 par acheteur)

### Formation et Communauté
- ✅ **5 Formations** complètes avec modules
- ✅ **20-80 Progressions** de formation (1-4 par producteur)
- ✅ **20 Posts** de forum avec réponses (40-120 réponses)
- ✅ **9 Badges** débloquables
- ✅ **5 Réalisations** à compléter
- ✅ **20-80 Badges** attribués aux utilisateurs

### Gestion
- ✅ **60-160 Stocks** (3-8 par producteur)
- ✅ **120-640 Mouvements** de stock
- ✅ **Alertes** de stock bas
- ✅ **100-300 Activités** de calendrier
- ✅ **40-120 Économies** calculées (eau, engrais, pertes)
- ✅ **20-60 ROI** tracking par parcelle
- ✅ **3 Achats groupés** actifs
- ✅ **129-430 Notifications** (3-10 par utilisateur)

## Prérequis

1. **Docker** doit être démarré
2. **MySQL** doit être accessible (port 3306)
3. **Variables d'environnement** correctement configurées

## Instructions d'Utilisation

### 1. Démarrer Docker Desktop

Sur macOS, lancez Docker Desktop depuis les Applications.

### 2. Démarrer les Services

```bash
cd /Users/amalamanemmanueljeandavid/Documents/Developement/agriculture
docker-compose up -d mysql
```

### 3. Attendre que MySQL soit prêt

```bash
docker-compose logs -f mysql
# Attendre le message: "mysqld: ready for connections"
# Appuyer sur Ctrl+C pour sortir des logs
```

### 4. Exécuter le Script de Seed

```bash
cd backend
node scripts/seed-complete.js
```

### 5. Vérifier les Données

```bash
# Se connecter à MySQL
docker exec -it agriculture-mysql-1 mysql -u agrosmart_user -p

# Entrer le mot de passe: agrosmart_secure_2024

# Vérifier les données
USE agrosmart_db;
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_parcelles FROM parcelles;
SELECT COUNT(*) as total_capteurs FROM capteurs;
SELECT COUNT(*) as total_mesures FROM mesures;
SELECT COUNT(*) as total_produits FROM marketplace_produits;
```

## Comptes de Test

Tous les comptes utilisent le mot de passe: `password123`

| Rôle | Téléphone | Email |
|------|-----------|-------|
| Admin | +2250101010101 | `admin@agrosmart.ci` |
| Agronome | +2250102020200 | `ibrahim.kone@agrosmart.ci` |
| Agronome | +2250102020201 | `mariam.diabate@agrosmart.ci` |
| Conseiller | +2250103030300 | `fanta.toure@agrosmart.ci` |
| Conseiller | +2250103030301 | `yacouba.soro@agrosmart.ci` |
| Producteur | +2250700000001 à +2250700000020 | `producteur1@agrosmart.ci` à `producteur20@agrosmart.ci` |
| Acheteur | +2250800000001 à +2250800000010 | `acheteur1@agrosmart.ci` à `acheteur10@agrosmart.ci` |
| Fournisseur | +2250900000001 à +2250900000005 | `fournisseur1@agrosmart.ci` à `fournisseur5@agrosmart.ci` |

## Fonctionnalités Testables

Avec ces données, vous pouvez tester:

### Mobile & Web
- ✅ Connexion / Inscription
- ✅ Dashboard avec statistiques réelles
- ✅ Gestion des parcelles
- ✅ Visualisation des capteurs et mesures
- ✅ Historique des alertes
- ✅ Diagnostics de maladies
- ✅ Marketplace (achat/vente)
- ✅ Panier et favoris
- ✅ Gestion des commandes
- ✅ Formations et progressions
- ✅ Forum et discussions
- ✅ Calendrier d'activités
- ✅ Gestion des stocks
- ✅ Suivi des économies et ROI
- ✅ Achats groupés
- ✅ Notifications
- ✅ Système de badges et points

## Nettoyage

Pour réinitialiser et relancer le seed:

```bash
node scripts/seed-complete.js
```

Le script nettoie automatiquement toutes les tables avant de les remplir.

## Durée d'Exécution

Le script prend environ **2-5 minutes** pour créer toutes les données.

## Résolution de Problèmes

### Erreur: "Can't reach database server"
- Vérifiez que Docker est démarré
- Vérifiez que MySQL tourne: `docker-compose ps`
- Redémarrez MySQL: `docker-compose restart mysql`

### Erreur: "Foreign key constraint fails"
- Le script gère automatiquement l'ordre des dépendances
- Si l'erreur persiste, vérifiez le schema Prisma

### Erreur: "Prisma Client not generated"
```bash
npx prisma generate
```

## Notes Importantes

- ⚠️ Ce script **SUPPRIME TOUTES LES DONNÉES** existantes avant le seed
- ✅ Toutes les données sont **réalistes** et cohérentes
- ✅ Les relations entre tables sont **correctement établies**
- ✅ Les dates sont **réalistes** (historique sur plusieurs mois)
- ✅ Les quantités et prix sont **dans les normes ivoiriennes**

## Support

En cas de problème, vérifiez:
1. Les logs Docker: `docker-compose logs mysql`
2. Les variables d'environnement dans `.env`
3. La connexion réseau à MySQL
