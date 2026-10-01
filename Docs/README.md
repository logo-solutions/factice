# Projet factice — Application modèle 3-tiers avec Ansible IaC

## Vue d'ensemble

**factice** est une application de référence conçue pour valider et documenter un pattern Ansible générique de déploiement (`roles/deploy_stack`).

L'application démontre une architecture **hétérogène à 3 tiers** :
- **Tier App** : conteneur Docker (Node.js/Express) — géré par `deploy_stack`
- **Tier Web** : reverse proxy natif (Caddy ou nginx) — processus macOS LaunchAgent
- **Tier BDD** : base de données native (PostgreSQL) — service Homebrew

### Objectifs

1. **Factoriser un rôle Ansible générique** : créer `roles/deploy_stack` qui gère le déploiement de conteneurs Docker de façon réutilisable et idempotente
2. **Valider le pattern** : prouver que `deploy_stack` fonctionne sur une application réelle (tests end-to-end)
3. **Documenter les patterns natifs** : montrer comment orchestrer des services Homebrew + LaunchAgent (tier Web et BDD) via Ansible, sans Docker

### Scope

**Inclus :**
- Rôle générique `deploy_stack` pour conteneurs Docker
- Rôles de support : `nexus`, `github_runner`, `factice`
- Application factice complète (code + CI/CD)
- Documentation architecture + diagrammes Mermaid

**Explicitement hors scope :**
- Multi-host infrastructure (local macOS uniquement)
- SSL/TLS (HTTP local seulement)
- Load balancing ou clustering
- Autres applications réelles — factice est un PoC standalone

## Structure du repo

```
factice/
├── Docs/
│   ├── README.md              # ce fichier
│   ├── architecture.md        # vue d'ensemble architecture 3-tiers
│   ├── flux-cicd.md           # diagramme Mermaid : CI/CD (push → runner → Nexus)
│   ├── flux-deploiement.md    # diagramme Mermaid : orchestration Ansible
│   ├── contrat-deploy-stack.md # contrat d'appel du rôle générique
│   └── decisions.md           # choix d'architecture (pourquoi Node.js, PostgreSQL natif, etc.)
├── app/
│   ├── src/
│   │   └── index.js           # serveur Express minimal
│   ├── package.json
│   └── Dockerfile
├── .github/workflows/
│   └── ci.yml                 # workflow CI : build + push Nexus
└── .gitignore
```

## Démarrer avec factice

### Prérequis

- Mac Mini avec NAS-LOGO Ansible déployé
- Nexus instance (sera déployé par `roles/nexus`)
- Runner GitHub Actions self-hosted (sera installé par `roles/github_runner`)

### Implémentation (Composants 0-6)

| Composant | Tâche | Status |
|---|---|---|
| 0 | Documentation (6 MD + Mermaid) | ✅ |
| 1-2 | `deploy_stack` + `roles/nexus` (NAS-LOGO) | ✅ |
| 3 | `roles/github_runner` (NAS-LOGO) | ✅ |
| 4 | Application code + CI/CD workflow | ✅ |
| 5 | `roles/factice` orchestration (NAS-LOGO) | ✅ |
| 6 | Multi-environment strategy (integration + production) | ✅ |

### Stratégie Multi-Environnement

**Deux environnements configurés :**

| Environnement | Port | Déploiement | URL |
|---|---|---|---|
| **Integration** | :8080 | Automatique (push main) | http://localhost:8080 |
| **Production** | :9080 | Manuel (workflow_dispatch) | http://localhost:9080 |

Chaque environnement a:
- Base de données PostgreSQL distincte (ports 5432 vs 5433)
- Utilisateur DB distinct (factice_integration vs factice_production)
- Répertoire d'installation distinct
- Credentiales vault distincts

### Validation End-to-End

#### Prérequis

1. **Secrets vault** — Ajouter à `NAS-LOGO/inventory/group_vars/all/vault.yml`:
```yaml
vault_nexus_admin_password: "..."
vault_nexus_url: "localhost:8082"
vault_factice_db_password: "..."
vault_factice_prod_db_password: "..."
vault_github_runner_token: "..."
```

2. **Runner GitHub Actions** — Token depuis Settings → Developer settings → Personal access tokens

#### Procédure de test

```bash
# 1. Déployer environment INTEGRATION
cd /Volumes/logousb/SSD/Projects/NAS-LOGO
ansible-playbook -i inventory/hosts deploy-factice-integration.yml \
  --vault-password-file ~/.nas-logo-vault-pass

# 2. Vérifier health (integration)
curl http://localhost:8080/health
# → Doit retourner 200 OK, traversant reverse proxy → app → DB

# 3. Test idempotence (deuxième run, ne doit rien changer)
ansible-playbook -i inventory/hosts deploy-factice-integration.yml
# Changements attendus: changed=0

# 4. Déployer PRODUCTION (manuel, demande confirmation)
ansible-playbook -i inventory/hosts deploy-factice-production.yml \
  --vault-password-file ~/.nas-logo-vault-pass
# Tape "yes" quand demandé

# 5. Vérifier health (production)
curl http://localhost:9080/health
# → Doit retourner 200 OK

# 6. Test CI/CD (push code → auto-deploy integration)
cd /Volumes/logousb/SSD/Projects/factice
git add .
git commit -m "test: trigger CI/CD"
git push origin main
# Vérifier: GitHub Actions → ci.yml workflow
# Vérifier: Image dans Nexus à localhost:8082/factice:latest
# Vérifier: http://localhost:8080/health reste 200 (re-deployé)

# 7. Test endpoint applicatif
curl http://localhost:8080/items
# → Doit retourner JSON array (liste des items PostgreSQL)

# 8. Créer un item (POST)
curl -X POST http://localhost:8080/items \
  -H "Content-Type: application/json" \
  -d '{"name":"test-item"}'
# → Doit retourner 201 + item créé

# 9. Vérifier item créé
curl http://localhost:8080/items
# → Doit inclure "test-item"

# 10. Reboot test (optionnel, valide auto-restart)
# Redémarrer Mac Mini
# Vérifier: curl http://localhost:8080/health → 200 après boot
```

### Critères d'Acceptation

| # | Critère | Validation |
|---|---|---|
| AC1 | Nexus déployé, repos créés | `curl http://localhost:8081/service/rest/v1/status` |
| AC2 | Runner enregistré | GitHub → Settings → Actions → Runners |
| AC3 | App integration up | `curl http://localhost:8080/health` → 200 |
| AC4 | App production up | `curl http://localhost:9080/health` → 200 |
| AC5 | CI/CD fonctionne | Push → GitHub Actions déclenché → image dans Nexus |
| AC6 | API /items fonctionne | GET/POST → JSON responses |
| AC7 | Idempotence | 2e run = `changed=0` |
| AC8 | Redémarrage robuste | Après restart Mac, tiers remontent auto |
| AC9 | Isolation environnement | Integration DB ≠ Production DB |
| AC10 | Chaîne complète 3-tiers | Reverse proxy (8080) → App container (3001) → PostgreSQL (5432) |

## Repository GitHub

**Factice repo:** https://github.com/logo-solutions/factice

- Source de la CI/CD (push → GitHub Actions)
- Runner self-hosted exécute les workflows
- Images publiées dans Nexus à localhost:8082/factice:*

## Architecture : les 3 tiers

Voir [architecture.md](architecture.md) pour un diagramme détaillé.

## Contrat d'appel de `deploy_stack`

Voir [contrat-deploy-stack.md](contrat-deploy-stack.md).

## Flux CI/CD

Voir [flux-cicd.md](flux-cicd.md).

## Flux de déploiement Ansible

Voir [flux-deploiement.md](flux-deploiement.md).

## Decisions d'architecture

Voir [decisions.md](decisions.md) : pourquoi Node.js, reverse proxy natif, PostgreSQL natif, Nexus provisionné par Ansible, runner self-hosted, etc.

## Mémoire projet

Mémorisé dans `/Users/logo/.claude/projects/memory/` :
- `factice_executive_summary.md` — Vue d'ensemble ship-ready
- `factice_project_structure.md` — Structure et objectifs
- `factice_decisions.md` — Justification des choix
- `factice_implementation_progress.md` — Progression (6 components)
- `factice_multienv_strategy.md` — Stratégie integration + production
- `feedback_factice_multienv_constraint.md` — Contraintes (2 envs, ports, "factice" in URLs)

---

## Status

✅ **SHIP-READY** — Tous les composants implémentés et documentés

Prêt pour:
1. Valider end-to-end (vault secrets + playbooks)
2. Tester CI/CD (push → GitHub Actions → Nexus)
3. Valider acceptation criteria (AC1-AC10)

Commits:
- Docs: `faed7a4`
- App code: `c95377a`
- CI/CD multi-env: `0c67904`
- NAS-LOGO roles: `5c5c1fb`, `3d18598`, `45b73e0`, `cfc335d`
