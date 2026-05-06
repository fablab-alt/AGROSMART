# Plan de remediation complet et roadmap

Ce plan est aligne sur les objectifs du projet "Agriculture de precision":
- securite des donnees et des acces (OTP, RBAC, chiffrement des flux),
- fiabilite de la plateforme (disponibilite, resilience, observabilite),
- qualite logicielle pour supporter l'echelle (500+ producteurs pilotes),
- conformite (protection des donnees, traçabilite, audits).

## Etat d'avancement

### Deja corrige dans cette iteration
- OTP renforce a l'inscription: compte cree en `EN_ATTENTE` + verification obligatoire avant emission de tokens.
- Suppression de l'auto-login post inscription sans verification OTP.
- Brute-force login branche sur succes/echec dans le controleur auth.
- Alignement RBAC admin: suppression du role inexistant `SUPER_ADMIN`.
- Durcissement production CORS: localhost desactive par defaut en production.
- Durcissement compose: `ALLOW_DEMO_START=false`, `ALLOW_LOCALHOST_CORS=false`.
- Upload video formation restreint au role admin.
- Suppression du fallback destructif `db push --accept-data-loss` en entrypoint prod.
- Build frontend bloque sur erreurs TypeScript.
- Refresh tokens stockes hashes en base (compatibilite avec tokens historiques).

## Roadmap executable PR par PR

## PR1 - Verrouillage securite critique (termine)
- Backend auth: OTP obligatoire a l'inscription.
- Backend auth: branchement anti brute-force sur les flux login/otp.
- Backend RBAC: roles coherents et explicites.
- Upload sensible: restriction admin.
- Infra prod: suppression mode demo permissif et CORS localhost.
- Frontend build: erreurs TypeScript bloquantes.

Critere d'acceptation:
- aucun token n'est emis sans OTP valide en inscription,
- un role non defini ne peut pas etre reference dans les routes,
- production refuse le demarrage si DB indisponible sans mode degrade.

## PR2 - Auth cookies HttpOnly + middleware Next (termine)
- Backend:
  - emettre access/refresh token en cookies `HttpOnly`, `Secure`, `SameSite`.
  - limiter la duree de vie access token et renforcer rotation refresh.
  - ajouter endpoint de logout qui invalide cookie + token en base.
- Frontend:
  - retirer persistance de tokens dans `localStorage`.
  - ajouter `middleware.ts` pour gating precoce des sections protegees.
  - adapter client API a l'auth par cookie.

Critere d'acceptation:
- absence de token dans `localStorage`,
- acces non authentifie redirige cote edge avant rendu page protegee.

## PR3 - CI/CD et garde-fous qualite (termine)
- Ajouter pipeline CI (GitHub Actions):
  - backend lint + scripts de validation critiques,
  - frontend lint + `tsc --noEmit` + build,
  - audit deps niveau modere et rapport artefact.
- Ajouter jobs de smoke tests API sur endpoints critiques (`/health`, auth, dashboard).

Critere d'acceptation:
- merge bloque si lint/ts/build echouent,
- artefacts de verification disponibles a chaque PR.

## PR4 - Durcissement conteneurs et disponibilite (termine)
- `docker-compose.yml`:
  - healthchecks backend/frontend,
  - `read_only`, `cap_drop`, `security_opt` quand possible,
  - `init: true` pour gestion des processus.
- Normaliser endpoints liveness/readiness.
- Aligner strictement ports compose/PM2/Nginx/docs.

Critere d'acceptation:
- redemarrage automatique base sur healthchecks,
- plus de divergence de ports entre docs et runtime.

## PR5 - Standardisation data access (termine)
- Reduire `queryRawUnsafe` et migrations SQL legacy vers Prisma parametre.
- Ajouter une couche repository pour les exceptions SQL inevitables.
- Connecter explicitement middleware soft-delete ou supprimer code mort.

Critere d'acceptation:
- aucun appel `Unsafe` non justifie,
- strategie de persistence documentee (Prisma-first).

## PR6 - Observabilite et securite operationnelle (priorite moyenne)
- Exposer et monitorer:
  - `health`, `readiness`, `metrics`.
- Ajouter alertes:
  - erreurs auth anormales,
  - echec migration,
  - latence API elevee,
  - saturation DB.
- Politique de logs:
  - format structure JSON,
  - retention/rotation homogenee,
  - exclusion des traces sensibles.

Critere d'acceptation:
- tableau de bord d'exploitation minimal disponible,
- runbook incident documente.

## PR7 - Robustesse UX et dette frontend (en cours)
- Uniformiser gestion d'erreurs UI (hook central + UX cohérente).
- Reduire les `any` sur modules critiques (auth/dashboard/admin).
- Remplacer classes Tailwind dynamiques fragiles par mappage explicite.
- Nettoyer logs debug client.

Critere d'acceptation:
- parcours critiques sans erreurs silencieuses,
- baisse des warnings TypeScript/ESLint sur zones prioritaires.

## PR8 - Conformite et gouvernance donnees (priorite moyenne)
- Mettre en place:
  - registre des traitements de donnees,
  - base legale/consentement explicite,
  - anonymisation pour analytics secondaires,
  - politique de retention + droit a l'effacement.
- Completer CGU/CGV/Privacy Policy dans le produit.

Critere d'acceptation:
- evidences de conformite disponibles pour audit interne.

## PR9 - Tests E2E metier (priorite moyenne)
- Scenarios minimum:
  - inscription + OTP + login,
  - acces dashboard protege,
  - RBAC admin/producteur,
  - upload admin uniquement,
  - refresh/logout session.

Critere d'acceptation:
- couverture E2E sur flux critiques de securite et de production.

## PR10 - Alignement objectifs metier agriculture de precision (continu)
- Verifier que les exigences projet restent tracees dans le produit:
  - alertes critiques multi-canaux,
  - support multilingue,
  - suivi rendement/ROI,
  - supervision capteurs et qualite des donnees.
- Ajouter KPIs trimestriels:
  - delai moyen d'alerte,
  - taux d'adoption OTP/MFA,
  - disponibilite plateforme,
  - latence API moyenne.

Critere d'acceptation:
- tableau de bord KPI pilotable pour la phase pilote et la montee en charge.

## Check-list "rien oublier"

- [x] OTP obligatoire inscription
- [x] suppression auto-login non verifie
- [x] RBAC coherent
- [x] anti brute-force branche
- [x] CORS prod strict
- [x] mode demo desactive en prod
- [x] fallback DB destructif retire
- [x] upload sensible restreint
- [x] TypeScript bloquant en build
- [x] refresh token hash en base
- [x] auth cookie HttpOnly cote backend + frontend
- [x] middleware Next de protection edge
- [x] CI complete (lint/test/build/audit)
- [x] healthchecks compose + hardening conteneurs
- [ ] unification des ports deploy
- [x] reduction SQL unsafe et normalisation Prisma
- [ ] observabilite + alerting production
- [ ] tests E2E securite metier
- [ ] chantier conformite juridique donnees

