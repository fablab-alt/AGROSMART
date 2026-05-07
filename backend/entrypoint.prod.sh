#!/bin/sh
set -e

# ==============================================
# AgroSmart Backend - Production Entrypoint
# Gère automatiquement:
#   1. Attente de MySQL
#   2. Migrations Prisma (création des tables)
#   3. Seed des données initiales (premier déploiement)
#   4. Démarrage du serveur
# ==============================================

echo "🚀 AgroSmart Backend - Démarrage en production..."
echo "=================================================="

# -----------------------------------------------
# 1. Attente de la disponibilité de MySQL
# -----------------------------------------------
echo "⏳ Attente de MySQL..."

MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if node -e "
    const mysql = require('mysql2/promise');
    const url = process.env.DATABASE_URL;
    mysql.createConnection(url)
      .then(conn => { conn.end(); process.exit(0); })
      .catch(() => process.exit(1));
  " 2>/dev/null; then
    echo "✅ MySQL est prêt!"
    break
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "   Tentative $RETRY_COUNT/$MAX_RETRIES - MySQL pas encore prêt, attente 5s..."
  sleep 5
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "❌ MySQL n'est pas disponible après $MAX_RETRIES tentatives. Arrêt."
  exit 1
fi

# -----------------------------------------------
# 2. Exécution des migrations Prisma
# -----------------------------------------------
echo ""
echo "📦 Exécution des migrations Prisma..."
echo "--------------------------------------"

if npx prisma migrate deploy; then
  echo "✅ Migrations appliquées avec succès!"
else
  echo "⚠️  Erreur lors des migrations. Tentative avec db push..."
  if npx prisma db push --accept-data-loss; then
    echo "✅ Schema synchronisé via db push!"
  else
    echo "❌ Impossible de synchroniser la base de données. Arrêt."
    exit 1
  fi
fi

# -----------------------------------------------
# 3. Seed des données initiales (premier déploiement)
# -----------------------------------------------

# Vérifier si c'est le premier déploiement (table users vide)
USER_COUNT=$(node -e "
  const { PrismaClient } = require('@prisma/client');
  const prisma = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });
  prisma.user.count()
    .then(count => { console.log(count); prisma.\$disconnect(); })
    .catch(() => { console.log('0'); prisma.\$disconnect(); });
" 2>/dev/null || echo "0")

if [ "$RUN_SEED" = "true" ] && [ "$USER_COUNT" = "0" ]; then
  echo ""
  echo "🌱 Premier déploiement détecté - Insertion des données initiales..."
  echo "-------------------------------------------------------------------"
  
  # Seed complet avec toutes les données de base
  if node scripts/seed-complete.js; then
    echo "✅ Données initiales insérées avec succès!"
    
    # Seed complémentaire (mesures, alertes, stocks, etc.)
    echo "🌱 Insertion des données complémentaires..."
    node scripts/seed-all-data.js 2>/dev/null || echo "⚠️  Seed complémentaire ignoré (optionnel)"
  else
    echo "⚠️  Le seed initial a échoué, mais le serveur va démarrer quand même."
  fi
elif [ "$USER_COUNT" != "0" ]; then
  echo ""
  echo "ℹ️  Base de données déjà peuplée ($USER_COUNT utilisateurs). Seed ignoré."
fi

# -----------------------------------------------
# 4. Démarrage du serveur Node.js
# -----------------------------------------------
echo ""
echo "🟢 Démarrage du serveur AgroSmart..."
echo "====================================="
echo "   Port: ${PORT:-3600}"
echo "   Env: ${NODE_ENV:-production}"
echo ""

exec node src/server.js
