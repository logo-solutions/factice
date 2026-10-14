# SRE Maturity : Factice

## Contexte

Factice est un exemple "par le livre" d'orchestration et de livraison IaC. Il illustre comment une application simple (Node.js + PostgreSQL) peut être déployée de manière reproductible et auditable à travers deux environnements (intégration et production) en utilisant un socle commun : CI/CD (GitHub Actions), Registry (Nexus) et Workflows Ansible.

Contrairement aux projets de transformation portant sur un portefeuille hétérogène, factice est une application **Dev inhouse unique**, avec une architecture de trois tiers aux modes d'exécution volontairement différents :

| Tier | Exécution |
|---|---|
| Web | Caddy natif (LaunchAgent) |
| App | Conteneur Docker |
| BDD | PostgreSQL natif |

## Matrice SRE appliquée à Factice

Comme factice est du **Dev inhouse pur**, on l'évalue principalement sur la colonne "Dev inhouse" (objectif : 10/10 sur tout ce qui s'applique).

### State of Play : État actuel vs Cible

| Domaine | Élément | État | Cible | Priorité |
|---|---|---|---|---|
| **TESTING** | | | | |
| Tests unitaires / intégration | ✅ Partiellement (tests app) | 10 | 🟢 |
| Smoke tests post-déploiement | ✅ Partiellement (curl /health) | 10 | 🟢 |
| Génération de jeux de test | ⚪ À venir | 10 | 🔵 |
| Mutation testing | ⚪ Non | 10 | 🟣 |
| Property-based testing | ⚪ Non | 10 | 🟣 |
| SAST (code source) | ⚪ Non | 10 | 🟡 |
| DAST (appli en fonctionnement) | ✅ Oui (contrôles santé) | 10 | 🟢 |
| Scan CVE du binaire / image | ✅ Oui (Nexus + image) | 10 | 🟢 |
| **DOCUMENTATION** | | | | |
| OpenAPI/Swagger | ⚪ Non | 10 | 🟡 |
| Changelog auto | ✅ Git / Nexus | 10 | 🟢 |
| Dependency graphs | ⚪ Non | 10 | 🟡 |
| Doc d'exploitation générée | ✅ Ansible + README | 10 | 🟢 |
| **CODE QUALITY** | | | | |
| Lint du code (app) | ✅ Oui (ESLint) | 10 | 🟢 |
| Lint du code Ansible | ⚪ ansible-lint | 10 | 🟢 |
| Couverture de tests | ⚪ Partielle | 10 | 🔵 |
| Architecture compliance | ⚪ Non | 10 | 🟣 |
| Dérive de configuration | ✅ Ansible (idempotent) | 10 | 🟢 |
| **SECRETS & COMPLIANCE** | | | | |
| Rotation automatique | ✅ Oui (Vault Ansible) | 10 | 🟢 |
| Credential scanning | ⚪ Non | 10 | 🟡 |
| Logs d'audit | ✅ Ansible logs | 10 | 🟢 |
| Piste d'audit immuable | ✅ Git + Nexus | 10 | 🟢 |
| Compliance checks (durcissement) | ✅ Partiellement (SELinux, firewall) | 10 | 🟡 |
| **DEPLOYMENT & ROLLBACK** | | | | |
| Installation / montée de version | ✅ Oui (Ansible) | 10 | 🟢 |
| Blue-green, canary | ⚪ Non (un seul instance) | 10 | 🟣 |
| Rollback par snapshot | ⚪ Non | 10 | 🟣 |
| Rollback piloté par les métriques | ⚪ Non | 10 | 🟣 |
| Feature flags | ⚪ Non | 10 | 🟣 |
| **MONITORING & OBSERVABILITY** | | | | |
| Supervision infra + healthchecks | ✅ Oui (curl /health) | 10 | 🟢 |
| Sondes synthétiques | ⚪ Non (basic healthcheck) | 10 | 🟡 |
| Métriques applicatives | ⚪ Non (pas de JMX, Prometheus) | 10 | 🟡 |
| Logs centralisés + indexation | ⚪ Non (logs locaux) | 10 | 🟡 |
| Routage d'alertes intelligent | ⚪ Non | 10 | 🟣 |
| Suivi SLO automatique | ⚪ Non | 10 | 🟣 |
| **ON-CALL & INCIDENT** | | | | |
| Astreinte, templates post-mortem | ⚪ Non | 10 | 🟣 |
| Runbooks générés depuis le code | ⚪ Non | 10 | 🔵 |
| **DATABASE** | | | | |
| Migrations de schéma | ✅ Oui (Prisma) | 10 | 🟢 |
| Sauvegarde + test de restauration | ⚪ Non (backup manuel) | 10 | 🟡 |
| Anonymisation des données | ⚪ Non | 10 | 🟣 |
| Monitoring des requêtes lentes | ⚪ Non | 10 | 🟡 |
| **WORKFLOW & ORCHESTRATION** | | | | |
| Workflows Ansible chaînés | ✅ Oui | 10 | 🟢 |
| Pipeline de build CI/CD | ✅ Oui (GitHub Actions) | 10 | 🟢 |
| Promotion avec gates | ✅ Oui (integ → prod) | 10 | 🟢 |
| Validation humaine | ✅ Oui (approvals GitHub) | 10 | 🟢 |
| Déclenchement événementiel | ✅ Oui (webhook registry → Ansible) | 10 | 🟢 |
| Réconciliation CMDB | ⚪ Non (pas de CMDB) | 10 | 🟣 |
| **REGISTRY** | | | | |
| Stockage versionné immuable | ✅ Oui (Nexus) | 10 | 🟢 |
| Normalisation du nommage | ✅ Oui (images Docker) | 10 | 🟢 |
| Métadonnées d'identité | ✅ Oui (buildSha, empreinte) | 10 | 🟢 |
| SBOM | ✅ Oui (CycloneDX) | 10 | 🟢 |
| Scan CVE / licences | ✅ Oui (Nexus) | 10 | 🟢 |
| Vérification signature | ⚪ Non | 10 | 🟣 |
| Mirror avec liste blanche | ⚪ Non (pas de dépendances externes) | 10 | 🟡 |
| Promotion de repo | ✅ Oui (staging → release) | 10 | 🟢 |
| Rétention / nettoyage | ✅ Oui (policies Nexus) | 10 | 🟢 |
| **RELEASES** | | | | |
| Version bumping semver | ✅ Oui (package.json) | 10 | 🟢 |
| Release notes auto | ✅ Oui (commits → release) | 10 | 🟢 |
| Signature des artefacts | ⚪ Non | 10 | 🟡 |
| Notifications de release | ✅ Oui (Slack) | 10 | 🟢 |

### Légende des priorités

- 🟢 **Implémenté** : Feature couverte, à maintenir
- 🔵 **Court terme** (2-4 sprints) : Enhancement mineur, dépendance faible
- 🟡 **Moyen terme** (5-8 sprints) : Feature major, dépendance modérée
- 🟣 **Hors périmètre** : Non applicable à factice (un seul tier, pas de HA, pas de incidents complexes)

## Priorités de complétude

### Phase 1 : Core observabilité (3-4 sprints)

1. Centraliser les logs (ELK ou Grafana Loki)
2. Ajouter des métriques applicatives (Prometheus exporter)
3. Configurer des alertes basiques (défaillance d'un tier)
4. Créer des runbooks simples pour les incidents courants

### Phase 2 : Hardening (4-6 sprints)

5. Scan SAST du code (SonarQube, snyk)
6. Credential scanning en CI (git-secrets, truffleHog)
7. Sauvegarde + test de restauration PostgreSQL
8. Vérification de signature des images Nexus

### Phase 3 : Avancé (7-8 sprints, facultatif)

9. Coberture de tests unitaires (Jest, nyc)
10. Mutation testing (Stryker)
11. Architecture compliance (c4model, ADR)

## Score global

| Catégorie | Score actuel | Cible | Poids |
|---|:---:|:---:|:---:|
| Testing | 6/10 | 10/10 | 15 % |
| Documentation | 7/10 | 10/10 | 10 % |
| Code Quality | 7/10 | 10/10 | 10 % |
| Secrets & Compliance | 8/10 | 10/10 | 15 % |
| Deployment & Rollback | 4/10 | 10/10 | 10 % |
| Monitoring & Observability | 2/10 | 10/10 | 15 % |
| On-call & Incident | 0/10 | 10/10 | 5 % |
| Database | 5/10 | 10/10 | 10 % |
| Workflow & Orchestration | 10/10 | 10/10 | 5 % |
| Registry | 9/10 | 10/10 | 5 % |
| **TOTAL PONDÉRÉ** | **5.75/10** | **10/10** | — |

## Prochaines étapes

1. Intégrer les logs Ansible et Docker dans Grafana Loki
2. Ajouter un exporter Prometheus pour les métriques Node.js
3. Configurer des alertes Prometheus/AlertManager
4. Écrire un runbook pour "Tier App ne répond pas"
