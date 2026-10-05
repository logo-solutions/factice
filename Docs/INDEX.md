# Documentation factice — Index complet

**factice** est une application modèle 3-tiers déployée par Ansible, validant un pattern de livraison CI/CD → Registry → Workflows Ansible avec gouvernance Nexus.

## 📚 Table des matières

### 🔧 Fondations et décisions

- **[architecture-3tiers.md](architecture-3tiers.md)** — Les trois tiers (App, Web, BDD) et leur orchestration
- **[decisions.md](decisions.md)** — 13 décisions d'architecture et leurs raisons
- **[trunk-based.md](trunk-based.md)** — Flux Git : tronc unique, branches courtes, promotion par empreinte
- **[sre.md](sre.md)** — Matrice de maturité SRE générique (COTS, Low code, Dev inhouse)
- **[sre-factice.md](sre-factice.md)** — SRE appliquée à factice : scores et évaluation

### 1️⃣ Fondations : réseau et architecture

**[1-fondations/](1-fondations/README.md)**

- [flux-et-reseau.md](1-fondations/flux-et-reseau.md) — Flux réels, diagramme avec frontières de confiance
- [flux-outils.md](1-fondations/flux-outils.md) — Flux cibles entre outils (exigences, ITSM, GitLab, registry, CMDB, documentation), décisions
- [kb.md](kb.md) — Base de connaissances : problèmes rencontrés, cause, correctif
- [flux-outils-factice.md](1-fondations/flux-outils-factice.md) — Mise en œuvre dans factice : correspondance des outils, état des flux, cycle d'un déploiement (ITSM, CMDB)
- [zones-securite.md](1-fondations/zones-securite.md) — Zones, frontières, accès d'administration
- [modele-menaces.md](1-fondations/modele-menaces.md) — Analyse STRIDE et mesures prioritaires

### 2️⃣ Socle : pipeline de livraison

**[2-pipeline-livraison/](2-pipeline-livraison/README.md)** — De la source au déploiement

#### CI/CD
**[ci-cd/](2-pipeline-livraison/ci-cd/README.md)**
- [pipeline-build-promotion.md](2-pipeline-livraison/ci-cd/pipeline-build-promotion.md) — Build, tests, publication, promotion (4 étapes), écarts connus
- [securite-pipeline.md](2-pipeline-livraison/ci-cd/securite-pipeline.md) — Durcissement, analyse, signature : état, écart, cible

#### Registry (Nexus)
**[registry/](2-pipeline-livraison/registry/README.md)**
- [nexus-architecture.md](2-pipeline-livraison/registry/nexus-architecture.md) — Décisions D1-D7, dépôts, promotion, immuabilité
- [nexus-spec.md](2-pipeline-livraison/registry/nexus-spec.md) — Spécification et mise en œuvre
- [nexus-presentation.md](2-pipeline-livraison/registry/nexus-presentation.md) — Présentation pour directeur

#### Orchestration (Ansible)
**[orchestration/](2-pipeline-livraison/orchestration/README.md)**
- [workflow-ansible.md](2-pipeline-livraison/orchestration/workflow-ansible.md) — Orchestration des 3 tiers (BDD, App, Web), contrôles de santé
- [deploy-stack-contract.md](2-pipeline-livraison/orchestration/deploy-stack-contract.md) — Contrat du rôle générique `deploy_stack` et écarts
- [bonnes-pratiques-ansible.md](2-pipeline-livraison/orchestration/bonnes-pratiques-ansible.md) — Qualité, tests, secrets, déploiement : état, écart, cible

### 3️⃣ Observabilité : visibilité et traçabilité

**[3-observabilite/](3-observabilite/README.md)** — Savoir ce qui tourne et ce qui s'est passé

- [metriques-et-tableaux.md](3-observabilite/metriques-et-tableaux.md) — Prometheus, Grafana, SLO
- [alertes-et-reactivite.md](3-observabilite/alertes-et-reactivite.md) — Alertes, escalade, runbooks
- [logs-et-traces.md](3-observabilite/logs-et-traces.md) — Logs structurés, traces distribuées, Loki
- [apm-et-performance.md](3-observabilite/apm-et-performance.md) — Instrumentation Node.js, profiling, benchmarks
- [cmdb.md](3-observabilite/cmdb.md) — CMDB NetBox : modèle, adaptateur, rapprochement avec le registry

### 4️⃣ Sécurité : protéger la chaîne

**[4-securite/](4-securite/README.md)** — Sécuriser de bout en bout

- [isolation-et-reseau.md](4-securite/isolation-et-reseau.md) — Zones, réseau, firewall, TLS
- [secrets-et-credentials.md](4-securite/secrets-et-credentials.md) — Vault Ansible, GitHub Secrets, rotation
- [audit-et-conformite.md](4-securite/audit-et-conformite.md) — Traçabilité, OWASP, ANSSI, conformité

### 5️⃣ Gouvernance : organiser et piloter

**[5-gouvernance/](5-gouvernance/README.md)** — Organiser l'adoption et les décisions

- [standards-et-guidelines.md](5-gouvernance/standards-et-guidelines.md) — Code standards, deployment gates, conventions de nommage

#### Automatisation
**[automatisation/](5-gouvernance/automatisation/README.md)**
- [architecture-automatisation.md](5-gouvernance/automatisation/architecture-automatisation.md) — Architecture de l'automatisation, réduction de la friction
- [presentation-directeur.md](5-gouvernance/automatisation/presentation-directeur.md) — Présentation stakeholder

### 📋 Exigences : ce qu'on demande aux éditeurs

**[exigences/](exigences/README.md)** — Référentiel vivant des exigences (contexte, enjeux, exigences par domaine, preuves attendues)

- [00-contexte-enjeux.md](exigences/00-contexte-enjeux.md) — Pourquoi, périmètre, acteurs
- [10-controle-acces-segregation.md](exigences/10-controle-acces-segregation.md) — Ségrégation logique, rôles, authentification, traçabilité des accès
- [organisation.md](exigences/organisation.md) — Règle dépôt / wiki, contrôles du pipeline, audit
- [modeles/](exigences/modeles/gabarit-exigence.md) — Gabarit d'exigence, page de consultation (wiki), réponse d'éditeur
- [journal.md](exigences/journal.md) — Historique des changements

---

## 🎯 Par audience

| Rôle | Commencer par | Puis lire |
|---|---|---|
| **Développeur** | trunk-based.md, architecture-3tiers.md | 2-pipeline-livraison/ci-cd |
| **DevOps / SRE** | 2-pipeline-livraison/, 3-observabilite/, 4-securite/ | decisions.md, sre-factice.md |
| **Architecte** | decisions.md, sre.md, 1-fondations/ | 2-pipeline-livraison/registry, 5-gouvernance/ |
| **Manager / PO** | sre-factice.md, 5-gouvernance/ | architecture-3tiers.md, trunk-based.md |
| **Compliance / Audit** | 4-securite/, 5-gouvernance/ | sre.md |

---

## 📊 Chronologie de lecture recommandée

1. **Jour 1 :** architecture-3tiers.md + decisions.md
2. **Jour 2 :** 1-fondations/ + 2-pipeline-livraison/
3. **Jour 3 :** trunk-based.md + 3-observabilite/
4. **Jour 4+:** 4-securite/ + 5-gouvernance/ + sre-factice.md

---

## 🔗 Liens utiles

- **GitHub :** https://github.com/logo-solutions/factice
- **Nexus :** http://localhost:8081 (dev) → Dépôts : 5001 (candidat), 5002 (release), 5003 (proxy), 5004 (groupe)
- **CI/CD :** `.github/workflows/ci.yml` dans le dépôt
- **Ansible :** `deploy-factice-{integration|production}.yml` + `provision-nexus.yml` + `roles/`

---

**Version :** 2026-10-02 | **Statut :** Documentation active, mise à jour continue
