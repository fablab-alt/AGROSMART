# ============================================================
# AgroSmart — Commandes Docker locales
# Usage : make <commande>
# ============================================================

.PHONY: help setup build up down logs restart shell-backend shell-db migrate seed clean nuke

# Couleurs
GREEN  = \033[0;32m
YELLOW = \033[0;33m
NC     = \033[0m

help: ## Affiche cette aide
	@echo ""
	@echo "$(GREEN)AgroSmart — Commandes Docker$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  $(YELLOW)%-18s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""

# ── Setup initial ────────────────────────────────────────────

setup: ## Copie .env.local.example → .env (première fois seulement)
	@if [ -f .env ]; then \
		echo "$(YELLOW).env existe déjà. Supprime-le manuellement si tu veux recommencer.$(NC)"; \
	else \
		cp .env.local.example .env; \
		echo "$(GREEN).env créé depuis .env.local.example$(NC)"; \
		echo "$(YELLOW)→ Édite .env et remplis les secrets JWT/COOKIE avant de continuer.$(NC)"; \
	fi

# ── Build & démarrage ────────────────────────────────────────

build: ## Rebuild toutes les images Docker (sans cache)
	docker compose build --no-cache

up: ## Démarre tous les services (build si nécessaire)
	docker compose up --build -d
	@echo ""
	@echo "$(GREEN)Services démarrés !$(NC)"
	@echo "  Frontend  → http://localhost:$$(grep FRONTEND_PORT .env | cut -d= -f2 || echo 3603)"
	@echo "  Backend   → http://localhost:$$(grep BACKEND_PORT .env | cut -d= -f2 || echo 3600)"
	@echo "  API docs  → http://localhost:$$(grep BACKEND_PORT .env | cut -d= -f2 || echo 3600)/api-docs"
	@echo ""
	@echo "Logs : make logs"

up-fg: ## Démarre en avant-plan (affiche les logs directement)
	docker compose up --build

down: ## Arrête tous les services
	docker compose down

restart: ## Redémarre tous les services
	docker compose restart

# ── Logs ─────────────────────────────────────────────────────

logs: ## Affiche les logs de tous les services
	docker compose logs -f

logs-backend: ## Logs du backend uniquement
	docker compose logs -f backend

logs-frontend: ## Logs du frontend uniquement
	docker compose logs -f frontend

logs-db: ## Logs de MySQL
	docker compose logs -f db

# ── Base de données ──────────────────────────────────────────

migrate: ## Applique les migrations Prisma manuellement
	docker compose exec backend npx prisma migrate deploy

seed: ## Insère les données de démo en base
	docker compose exec backend node scripts/seed.js

studio: ## Ouvre Prisma Studio (explorateur de DB) sur le port 5555
	docker compose exec backend npx prisma studio --port 5555 --browser none &
	@echo "$(GREEN)Prisma Studio → http://localhost:5555$(NC)"

# ── Shells ───────────────────────────────────────────────────

shell-backend: ## Ouvre un shell dans le conteneur backend
	docker compose exec backend sh

shell-db: ## Connexion MySQL CLI vers la DB distante (via backend container)
	docker compose exec backend npx prisma db pull --print

# ── Statut ───────────────────────────────────────────────────

ps: ## Affiche l'état des conteneurs
	docker compose ps

health: ## Vérifie la santé de l'API
	@curl -sf http://localhost:$$(grep BACKEND_PORT .env | cut -d= -f2 || echo 3600)/health | python3 -m json.tool || echo "Backend non joignable"

# ── Nettoyage ────────────────────────────────────────────────

clean: ## Arrête et supprime les conteneurs (garde les volumes/données)
	docker compose down --remove-orphans

nuke: ## ⚠️  Supprime TOUT : conteneurs + volumes (perd les données DB)
	@echo "$(YELLOW)⚠️  Ceci va supprimer toutes les données MySQL. Confirme avec : make nuke CONFIRM=yes$(NC)"
	@[ "$(CONFIRM)" = "yes" ] || exit 1
	docker compose down -v --remove-orphans
	@echo "$(GREEN)Tout supprimé.$(NC)"
