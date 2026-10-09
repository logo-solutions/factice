# factice — Application modèle 3-tiers déployée par Ansible

**factice** est une application de référence qui sert à valider un pattern de déploiement Ansible et la chaîne de livraison autour de Nexus : build, candidat, promotion, release, déploiement par empreinte.

Elle tourne sur un hôte macOS, avec une architecture hétérogène à trois tiers :

| Tier | Technologie | Géré par |
|---|---|---|
| App | Conteneur Docker (Node.js / Express) | `roles/compose_deploy` |
| Web | Reverse proxy Caddy natif, LaunchAgent macOS | `roles/factice` |
| BDD | PostgreSQL natif, service Homebrew | `roles/factice` |

## Objectifs

1. Disposer d'un rôle Ansible générique, `compose_deploy` (squelette commun à maisonnettev2, Nexus et factice depuis le 2026-10-09 ; auparavant `deploy_stack`), qui déploie une pile Docker de façon réutilisable et idempotente.
2. Prouver ce rôle sur une application réelle, avec des tests de bout en bout.
3. Documenter l'orchestration de services natifs (Homebrew et LaunchAgent) par Ansible, sans Docker.
4. Mettre en œuvre la gouvernance des artefacts décrite dans `Docs/2-pipeline-livraison/registry/` : dépôts candidat et release, promotion contrôlée, immuabilité des releases.

**Hors périmètre** : multi-hôte, TLS (HTTP local uniquement), répartition de charge, autres applications.

## Documentation

### Vue d'ensemble

| Document | Contenu |
|---|---|
| [INDEX.md](INDEX.md) | Index hiérarchique complet |
| [architecture-3tiers.md](architecture-3tiers.md) | Les trois tiers et leur orchestration |
| [sre.md](sre.md) | Transformation et industrialisation |
| [sre-factice.md](sre-factice.md) | Matrice SRE appliquée à factice |
| [decisions.md](decisions.md) | Choix d'architecture et leurs raisons |
| [trunk-based.md](trunk-based.md) | Flux de travail Git : tronc unique, branches courtes |

### Sections (hiérarchie 5 niveaux)

| Section | Contenu |
|---|---|
| [1-fondations/](1-fondations/README.md) | Flux, zones de sécurité, modèle de menaces |
| [2-pipeline-livraison/](2-pipeline-livraison/README.md) | CI/CD et sécurité du pipeline, Registry Nexus, Ansible et bonnes pratiques |
| [3-observabilite/](3-observabilite/README.md) | Métriques, alertes, logs, traces, APM |
| [4-securite/](4-securite/README.md) | Isolation réseau, secrets, audit, conformité |
| [5-gouvernance/](5-gouvernance/README.md) | Standards, guidelines, automatisation |

## Structure du dépôt

```
factice/
├── Docs/                          # documentation (ce dossier)
├── app/                           # application Node.js / Express
│   ├── src/index.js
│   ├── tests/
│   └── Dockerfile
├── roles/
│   ├── compose_deploy/            # rôle générique de déploiement Docker (squelette commun)
│   ├── factice/                   # orchestration des trois tiers
│   ├── nexus/                     # dépôts, droits, nettoyage, conformité
│   └── github_runner/             # runner GitHub Actions auto-hébergé
├── scripts/nexus/                 # publication, promotion, SBOM, événement, recette
├── inventory/                     # hôte local et variables
├── deploy-factice-integration.yml
├── deploy-factice-production.yml
├── provision-nexus.yml
└── .github/workflows/ci.yml
```

## Environnements

| | Intégration | Production |
|---|---|---|
| Déclenchement | Automatique à chaque push sur `main` | Manuel (`workflow_dispatch`), environnement GitHub protégé |
| Santé | `http://localhost:8070/health` | `http://localhost:9080/health` |
| Conteneur applicatif | port 3000 | port 9001 |
| PostgreSQL | port 5432, base et utilisateur `factice_integration` | port 5432 (même cluster), base et utilisateur `factice_production` |

Chaque environnement a son propre répertoire d'installation, sa base, son utilisateur de base de données et ses secrets.

## Chaîne CI/CD

Le workflow `.github/workflows/ci.yml` s'exécute sur le runner auto-hébergé :

1. **build** : tests bloquants, génération du SBOM, publication de l'image dans `docker-candidat` (compte `svc-build-factice-app`).
2. **promote** : contrôles de complétude, de provenance (le commit appartient à une branche protégée) et d'empreinte, puis republication dans `docker-release` avec le manifeste et le SBOM (compte `svc-promotion`).
3. **deploy-integration** et **deploy-production** : déploiement de l'image release par empreinte (compte `svc-deploiement`, lecture seule), contrôle de santé, puis événement de déploiement.

Aucune étiquette `latest` n'est utilisée. Une release est immuable.

## Mise en route

### Prérequis

- Hôte macOS avec Docker (Colima), Ansible et les collections Ansible utilisées par les rôles.
- Nexus Repository 3 Community, géré par `roles/nexus` ou déjà en service.
- Runner GitHub Actions auto-hébergé, installé par `roles/github_runner`.

### Secrets

| Secret | Emplacement |
|---|---|
| Mots de passe de l'inventaire (`vault_*`) | `inventory/group_vars/local/vault.yml` : valeurs de remplacement dans le dépôt, à chiffrer avec `ansible-vault` ; mot de passe du coffre dans `~/.factice-vault-pass` |
| Mot de passe administrateur Nexus | fichier `nexus-admin.yml` hors dépôt (ignoré par Git), ou coffre Ansible |
| Mots de passe des comptes de service Nexus | générés dans `.secrets/nexus/` (hors dépôt), conservés dans Bitwarden (`factice-nexus`) |
| Secrets GitHub du dépôt | `NEXUS_BUILD_PASSWORD`, `NEXUS_PROMOTION_PASSWORD`, `NEXUS_DEPLOY_PASSWORD`, et `CMDB_TOKEN` si besoin |

Variables GitHub du dépôt : `NEXUS_URL`, `NEXUS_DOCKER_CANDIDAT`, `NEXUS_DOCKER_RELEASE`, et `CMDB_EVENT_URL` si besoin.

### Configurer Nexus

```bash
ansible-playbook provision-nexus.yml \
  -e nexus_manage_container=false -e nexus_container_name=nexus \
  -e nexus_eula_accepted=true -e @nexus-admin.yml
```

`nexus_eula_accepted=true` est une décision de l'exploitant : la licence de la Community Edition n'est jamais acceptée par défaut. Le conteneur doit publier les ports Docker 5001 à 5004 (candidat, release, proxy, groupe). Détails dans [registry/README.md](2-pipeline-livraison/registry/README.md).

### Déployer

```bash
ansible-playbook deploy-factice-integration.yml --vault-password-file ~/.factice-vault-pass
curl http://localhost:8070/health

ansible-playbook deploy-factice-production.yml --vault-password-file ~/.factice-vault-pass
curl http://localhost:9080/health
```

Pour déployer une release précise, ajouter `-e factice_release_image=<hôte>/factice.app/factice@<empreinte>`.

### Recette Nexus

```bash
docker build -t factice-recette:local app
IMAGE=factice-recette:local scripts/nexus/recette.sh
```

La recette joue le cycle complet (publication, promotion) puis contrôle R1, R2, R3, R4, R8, R11 et le cloisonnement des comptes. Elle laisse des artefacts de test dans l'instance.

## Critères d'acceptation

| # | Critère | Validation |
|---|---|---|
| AC1 | Nexus conforme, dépôts créés | `provision-nexus.yml` : `changed=0` au second passage, « Instance conforme » |
| AC2 | Recette Nexus | `scripts/nexus/recette.sh` : tous les contrôles PASS |
| AC3 | Runner enregistré | GitHub, Settings, Actions, Runners |
| AC4 | Intégration disponible | `curl http://localhost:8070/health` renvoie 200 |
| AC5 | Production disponible | `curl http://localhost:9080/health` renvoie 200 |
| AC6 | CI/CD fonctionnelle | Push sur `main` : build, candidat, promotion, release, déploiement |
| AC7 | API `/items` | GET et POST renvoient du JSON |
| AC8 | Idempotence | Second passage d'un playbook : `changed=0` |
| AC9 | Redémarrage robuste | Après redémarrage du Mac, les tiers remontent seuls |
| AC10 | Isolation des environnements | Bases et utilisateurs distincts entre intégration et production |
| AC11 | Chaîne complète | Reverse proxy, conteneur applicatif, PostgreSQL |

### Critères proposés (pas encore applicables)

Ces critères traduisent les cibles de [securite-pipeline.md](2-pipeline-livraison/ci-cd/securite-pipeline.md) et de [bonnes-pratiques-ansible.md](2-pipeline-livraison/orchestration/bonnes-pratiques-ansible.md). Ils ne sont pas retenus tant que le workflow et les rôles ne les mettent pas en œuvre.

| N° | Critère | Vérification envisagée |
|---|---|---|
| AC12 | Analyse statique | `ansible-lint` (profil `production`), `yamllint` et `actionlint` sans erreur |
| AC13 | Analyse des vulnérabilités | aucune vulnérabilité `CRITICAL` ou `HIGH` corrigeable dans l'image promue |
| AC14 | Signature vérifiée | `cosign verify` réussi sur l'empreinte avant chaque déploiement |
| AC15 | Droits minimaux | workflow avec `permissions` explicites ; production bloquée par `change-gate` (changement ITSM approuvé) |
| AC16 | Secrets chiffrés | aucun secret en clair dans le dépôt ; `vault.yml` chiffré |
| AC17 | Exposition maîtrisée | balayage depuis une autre machine : seuls les ports prévus répondent |

## Limites connues

- Le déploiement complet des deux environnements (connexion du conteneur à PostgreSQL, démarrage du LaunchAgent Caddy, tirage d'une release) n'a pas encore été joué de bout en bout : seuls la syntaxe des playbooks et la validité du Caddyfile sont contrôlées.
- Aucun runner GitHub n'est encore enregistré : la CI ne s'exécute pas tant que `roles/github_runner` n'a pas été appliqué.
- Le fichier `inventory/group_vars/local/vault.yml` contient des valeurs de remplacement en clair, à chiffrer avec `ansible-vault`.
- Écarts de la mise en œuvre Nexus avec la spécification (promotion par republication, pas d'analyse de vulnérabilités, un port par dépôt Docker, etc.) : voir [registry/README.md](2-pipeline-livraison/registry/README.md).

## Dépôt GitHub

https://github.com/logo-solutions/factice
