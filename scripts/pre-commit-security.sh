#!/bin/bash
# ==============================================
# Git Pre-Commit Hook - Détection de Secrets
# ==============================================
# Ce hook empêche les commits contenant des secrets
# 
# Installation:
#   chmod +x scripts/pre-commit-security.sh
#   cp scripts/pre-commit-security.sh .git/hooks/pre-commit
# ==============================================

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 Vérification de sécurité avant commit..."

# Patterns à détecter (mots de passe, clés API, etc.)
FORBIDDEN_PATTERNS=(
    "password\s*=\s*['\"][^'\"]{8,}['\"]"
    "api[_-]?key\s*=\s*['\"][^'\"]{10,}['\"]"
    "secret\s*=\s*['\"][^'\"]{10,}['\"]"
    "token\s*=\s*['\"][^'\"]{20,}['\"]"
    "private[_-]?key"
    "BEGIN (RSA|DSA|EC|OPENSSH) PRIVATE KEY"
    "AKIA[0-9A-Z]{16}"  # AWS Access Key
    "mongodb(\+srv)?://[a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+@"  # MongoDB URI avec credentials
    "mysql://[a-zA-Z0-9_-]+:[a-zA-Z0-9_-]+@"  # MySQL URI avec credentials
)

# Fichiers à vérifier (seulement les fichiers dans le staging)
FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [ -z "$FILES" ]; then
    echo -e "${GREEN}✅ Aucun fichier à vérifier${NC}"
    exit 0
fi

FOUND_SECRETS=0

# Vérifier chaque fichier
for FILE in $FILES; do
    # Ignorer les fichiers dans .gitignore et certains types
    if git check-ignore -q "$FILE"; then
        continue
    fi
    
    # Ignorer les fichiers binaires et certains types
    case "$FILE" in
        *.png|*.jpg|*.jpeg|*.gif|*.pdf|*.zip|*.tar.gz|*.ico)
            continue
            ;;
        *.lock|package-lock.json|yarn.lock|composer.lock)
            continue
            ;;
        */.env.example|*/.env.*.example|*/example.env|.env.*.example|*.env.example)
            continue  # Les exemples .env sont OK
            ;;
        README.md|DEPLOYMENT.md|SECURITY_ACTIONS.md|PRE_PUSH_CHECKLIST.md|CONTRIBUTING.md)
            continue  # Documentation avec exemples légitimes
            ;;
    esac
    
    # Rechercher les patterns suspects
    for PATTERN in "${FORBIDDEN_PATTERNS[@]}"; do
        if git diff --cached "$FILE" | grep -iE "$PATTERN" > /dev/null; then
            if [ $FOUND_SECRETS -eq 0 ]; then
                echo -e "\n${RED}❌ SECRETS DÉTECTÉS!${NC}\n"
            fi
            echo -e "${YELLOW}Dans: $FILE${NC}"
            echo -e "   Pattern: $PATTERN"
            FOUND_SECRETS=1
        fi
    done
done

# Vérifier les fichiers .env (sauf les .example)
ENV_FILES=$(echo "$FILES" | grep -E '(^|/)\.env$|\.env\.(local|production|development|test)$' | grep -v '\.example$')
if [ ! -z "$ENV_FILES" ]; then
    echo -e "\n${RED}❌ FICHIER .env DÉTECTÉ!${NC}"
    echo -e "${YELLOW}Les fichiers suivants ne doivent PAS être commités:${NC}"
    echo "$ENV_FILES" | while read -r file; do
        echo "   - $file"
    done
    echo ""
    echo -e "${YELLOW}Pour corriger:${NC}"
    echo "   git reset HEAD $ENV_FILES"
    echo ""
    FOUND_SECRETS=1
fi

if [ $FOUND_SECRETS -eq 1 ]; then
    echo -e "\n${RED}🚫 COMMIT BLOQUÉ${NC}"
    echo -e "${YELLOW}Des secrets ou fichiers sensibles ont été détectés.${NC}\n"
    echo "Actions à prendre:"
    echo "  1. Retirer les secrets du code"
    echo "  2. Utiliser des variables d'environnement"
    echo "  3. Vérifier .gitignore"
    echo ""
    echo "Pour forcer le commit (DÉCONSEILLÉ):"
    echo "  git commit --no-verify"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Aucun secret détecté - Commit autorisé${NC}"
exit 0
