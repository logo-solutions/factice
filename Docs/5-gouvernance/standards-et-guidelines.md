# Standards et guidelines

## Gouvernance de factice

Factice est un exemple de "par le livre" : chaque décision architecture, déploiement et opérationnel est documentée et reversible.

## Standards architecturaux

### Principe du moindre privilège

- Chaque tier ne fait qu'une chose
- Chaque service accède uniquement aux ressources dont il a besoin
- Aucun secret en code, tous en Vault

### Immutabilité

- **Code** : commit SHA = version immuable
- **Images Docker** : référencées par digest, jamais par tag
- **Configuration** : Ansible playbooks versionnés, immuables après déploiement
- **Artefacts** : promotions sont unidirectionnelles (candidate → release)

### Reproductibilité

- Même commit + même Ansible version + même Nexus state = même déploiement
- Aucun état caché sur l'hôte (tout vient de Nexus ou Git)
- Redéploiement 2x consécutives → `changed=0` garanti

## Standards de code

### Node.js (Tier App)

- **Linting** : ESLint (config partagée `shared/eslint-config`)
- **Formatting** : Prettier (config partagée)
- **Type checking** : TypeScript strict mode
- **Tests** : Jest + supertest (routes HTTP)
- **Couverture minimum** : 60 % (à améliorer)

Commandes standard :

```bash
npm run lint       # ESLint + Prettier check
npm run format     # Auto-format avec Prettier
npm run type-check # tsc --noEmit
npm run test       # Jest
npm run build      # Compile TypeScript → dist/
```

### Ansible (Roles)

- **Linting** : ansible-lint (role names, variable naming)
- **Structure** : `tasks/`, `handlers/`, `templates/`, `defaults/`, `vars/`
- **Naming** : `role_name_variable`, `- name: lowercase description`
- **Idempotence** : Tous les roles doivent pouvoir s'exécuter 2x sans changement

Commandes standard :

```bash
ansible-lint roles/*/
ansible-playbook site.yml --syntax-check
ansible-playbook site.yml --diff (dry-run)
```

### Ansible Vault (Secrets)

- Toute variable commençant par `vault_` est encryptée
- Clé de chiffrement générée une fois, stockée hors Git
- Accès limité au CI/CD et opérateurs

## Standards de déploiement

### CI/CD (GitHub Actions)

Le workflow de référence est `.github/workflows/ci.yml`, décrit dans [pipeline-build-promotion.md](../2-pipeline-livraison/ci-cd/pipeline-build-promotion.md). Principes :

- une étape `build` qui lance les tests et construit l'image ;
- une étape `promote` qui republie l'image dans `docker-release` après contrôles ;
- le déploiement d'intégration est automatique, celui de production est manuel, sur un environnement GitHub protégé ;
- les images sont référencées par empreinte, jamais par étiquette `latest`.

**Gates** :

- Tests doivent passer avant fusion
- Déploiement intégration automatique
- Déploiement production = lancement manuel et approbation de l'environnement GitHub

### Promotion Nexus

```
Candidat (docker-candidat)
  ↓ (contrôles de complétude, de provenance et d'empreinte)
Release (docker-release, immuable)
  ↓ (le workflow lance Ansible)
Déploiement (intégration puis production, par empreinte)
```

Chaque étape laisse une trace Git + journal d'audit Nexus. L'analyse de vulnérabilités n'est pas encore en place (voir le TODO).

## Standards opérationnels

### Naming conventions

| Ressource | Format | Exemple |
|---|---|---|
| Docker image | `service-name@sha256:<empreinte>` | `factice@sha256:ab12…` |
| Nexus repo | `docker-{stage}` | `docker-candidat`, `docker-release` |
| Environment | `{env}-{app}` | `integration-factice`, `production-factice` |
| Ansible group | `{env}` | `[integration]`, `[production]` |
| PostgreSQL user | `{app}_{env}` | `factice_integration`, `factice_production` |
| Caddy config | `{env}.Caddyfile` | `integration.Caddyfile`, `production.Caddyfile` |

### Version semver

Format : `MAJOR.MINOR.PATCH`

- **MAJOR** : Breaking changes (schema BD, API incompatible)
- **MINOR** : Features non-breaking
- **PATCH** : Bugfixes

Exemple progression :

```
v1.0.0 (initial release)
v1.1.0 (nouvelle route GET /health)
v1.1.1 (bugfix latency)
v2.0.0 (nouvelle schema BD)
```

Version automatiquement bump en CI (commitlint + standard-version).

## Standards de documentation

### Commandes obligatoires

Chaque projet expose ces commandes :

```bash
npm run dev         # Dev server (integ only)
npm run build       # Compile pour prod
npm run lint        # Linting
npm run format      # Auto-format
npm run type-check  # TypeScript check
npm run test        # Tests
```

### Fichiers obligatoires

Chaque repo contient :

- `README.md` : Quickstart, contexte, dépendances
- `CLAUDE.md` : Instructions de développement locales
- `CONTRIBUTING.md` : Process PR, style guide
- `Architecture.md` ou `.../architecture.md` : Vue d'ensemble système

### Changelogs

Maintenu automatiquement à partir des commits (Conventional Commits) :

```
v1.2.3 (2026-10-02)

### Features
- Add GET /health healthcheck endpoint

### Bug Fixes
- Fix latency spike on POST /items when database is busy

### Breaking Changes
None

### Contributors
- John Doe <john@example.com>
```

## Standards de gestion du changement

### Approbations requises

| Changement | Approbateurs | Délai |
|---|---|---|
| Code app (non-secret) | 1 reviewer + tests | N/A (PR) |
| Infrastructure (Ansible) | 1 ops + 1 devops | N/A (avant merge main) |
| Secrets (Vault) | DBA + Ops | 24 h |
| Déploiement production | Tech lead + Ops | Approvals GitHub |

### Rollback

Tout déploiement doit être rollback-able en < 10 minutes :

- Nexus stocke les deux dernières releases
- Ansible peut redéployer une version antérieure
- PostgreSQL migrations sont reversible (up/down)

## Audit de conformité

Vérifications mensuelles :

- [ ] Code linted + type-checked
- [ ] Tests coverage ≥ 60 %
- [ ] Secrets ne sont pas en logs
- [ ] Déploiements approuvés (audit trail)
- [ ] CVE scan clean (ou justifié)
- [ ] Runbooks à jour

## Prochaines étapes

1. Configurer commitlint (Conventional Commits)
2. Implémenter standard-version (bump semver auto)
3. Créer template PR (checklist: tests, docs, runbooks)
4. Planifier audit mensuel de conformité
5. Documenter runbooks pour 5 scénarios critiques
