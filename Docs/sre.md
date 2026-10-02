# Transformation Industrialisation 

## Panorama
### Légende

| Score | Signification |
|:---:|---|
| **0** | Non concerné ou impossible (code fermé) |
| **5** | Partiellement concerné (enveloppe de déploiement seulement, ou uniquement nos extensions/paramétrages) |
| **10** | Pleinement automatisable (100 % concerné) |
### Types de solution

- **COTS** : binaire livré, support éditeur, pas de code source. On n'agit qu'en boîte noire.
- **Low code** : plateforme configurée et étendue. Du code uniquement sur nos extensions, modules et configurations.
- **Dev inhouse**

| Élément | COTS | Low code | Dev inhouse |
|---|:---:|:---:|:---:|
| **TESTING** | | | |
| Tests unitaires / intégration du code | 0 | 5 | 10 |
| Recette boîte noire (smoke tests post-déploiement) | 10 | 10 | 10 |
| Génération de jeux de test | 5 | 5 | 10 |
| Mutation testing | 0 | 5 | 10 |
| Property-based testing | 0 | 0 | 10 |
| SAST (code source) | 0 | 5 | 10 |
| DAST (appli en fonctionnement) | 10 | 10 | 10 |
| Scan CVE du binaire / de l'image livrée | 10 | 10 | 10 |
| **DOCUMENTATION** | | | |
| OpenAPI/Swagger généré depuis le code | 0 | 5 | 10 |
| Changelog auto (commits → release notes) | 0 | 5 | 10 |
| Dependency graphs | 0 | 5 | 10 |
| Doc d'exploitation générée depuis les rôles Ansible | 5 | 10 | 10 |
| **CODE QUALITY** | | | |
| Lint du code de déploiement (Ansible, scripts) | 10 | 10 | 10 |
| Lint du code applicatif | 0 | 5 | 10 |
| Couverture de tests | 0 | 5 | 10 |
| Architecture compliance | 0 | 0 | 10 |
| Détection de code dupliqué | 0 | 5 | 10 |
| Détection de dérive de configuration | 5 | 10 | 10 |
| **SECRETS & COMPLIANCE** | | | |
| Rotation automatique des secrets | 5 | 5 | 10 |
| Credential scanning des dépôts | 5 | 10 | 10 |
| Parsing des logs d'audit | 5 | 10 | 10 |
| Piste d'audit immuable conçue par nous | 0 | 0 | 10 |
| Compliance checks infra (durcissement, ANSSI) | 10 | 10 | 10 |
| **DEPLOYMENT & ROLLBACK** | | | |
| Installation / montée de version (Ansible) | 10 | 10 | 10 |
| Blue-green, canary | 0 | 0 | 10 |
| Rollback par snapshot / restauration | 5 | 5 | 10 |
| Rollback piloté par les métriques | 0 | 0 | 10 |
| Feature flags | 0 | 0 | 10 |
| **MONITORING & OBSERVABILITY** | | | |
| Supervision infra, healthchecks | 10 | 10 | 10 |
| Sondes synthétiques | 10 | 10 | 10 |
| Métriques applicatives (JMX, instrumentation) | 0 | 5 | 10 |
| Logs centralisés + indexation | 5 | 10 | 10 |
| Routage d'alertes intelligent | 10 | 10 | 10 |
| Suivi SLO automatique | 5 | 10 | 10 |
| **ON-CALL & INCIDENT** | | | |
| Astreinte, war room, templates post-mortem | 10 | 10 | 10 |
| Runbooks générés depuis le code | 0 | 5 | 10 |
| Ticket automatique chez l'éditeur | 10 | 0 | 0 |
| **DATABASE** | | | |
| Migrations de schéma | 0 | 0 | 10 |
| Sauvegarde + test de restauration | 10 | 10 | 10 |
| Anonymisation des données | 0 | 5 | 10 |
| Monitoring des requêtes lentes | 0 | 5 | 10 |
| **WORKFLOW & ORCHESTRATION** | | | |
| Workflows Ansible chaînés (déploiement → smoke tests → notification) ¹ | 10 | 10 | 10 |
| Pipeline de build CI/CD ² (code source + déploiement + configuration) | 5 | 10 | 10 |
| Promotion entre environnements avec gates (dev → recette → prod) ² | 10 | 10 | 10 |
| Validation humaine intégrée (change, ITSM) ¹ | 10 | 10 | 10 |
| Déclenchement événementiel (webhook registry → Ansible) ¹ | 10 | 10 | 10 |
| Réconciliation CMDB après déploiement ¹ | 10 | 10 | 10 |
| Workflows métier internes aux applications (ex. circuits d'approbation) | 0 | 5 | 10 |

¹ = Workflow **Ansible** (orchestration de déploiement)  
² = Workflow **CI/CD** (GitHub Actions, build et promotion)

| **REGISTRY** | | | |
|---|---|---|---|
| Stockage versionné et immuable des artefacts | 10 | 10 | 10 |
| Normalisation du nommage à l'ingestion | 10 | 10 | 10 |
| Métadonnées d'identité (buildSha, checksums) | 5 | 5 | 10 |
| SBOM | 5 | 5 | 10 |
| Scan CVE / licences à l'ingestion | 10 | 10 | 10 |
| Vérification signature / checksum éditeur | 10 | 5 | 0 |
| Mirror des dépendances (Galaxy, Maven, Docker) avec liste blanche | 0 | 5 | 10 |
| Promotion de repo (staging → release) | 10 | 10 | 10 |
| Rétention / nettoyage | 10 | 10 | 10 |
| **RELEASES** | | | |
|---|---|---|---|
| Version bumping semver automatique | 0 | 5 | 10 |
| Génération des release notes | 0 | 5 | 10 |
| Signature des artefacts que nous produisons | 0 | 5 | 10 |
| Notifications de release | 10 | 10 | 10 |

## Commentaires

**COTS** : déploiement, workflows Ansible, registry, supervision, sauvegarde.

**Low code** : plutôt 5, car la chaîne qualité ne s'applique qu'aux extensions, pas à la plateforme.

**Dev inhouse** : presque tout à 10, mais tout est à construire et à maintenir.

**Pipeline CI/CD, Workflows Ansible et Registry** sont les trois blocs où les trois colonnes convergent le plus. C'est le socle commun à industrialiser en premier, car ils forment une chaîne indissociable : CI/CD → Registry → Workflows Ansible.

## Contexte

Applications avec des formes de livraison hétérogènes : sources Java, conteneurs éditeur, conteneurs maison, binaires COTS.

1. Pas de point d'entrée unique : les artefacts sont conservés au niveau de chaque équipe, sans stockage centralisé ni versionné.
2. Déploiements manuels : scripts de type `deploy.sh` lancés à la main, sans orchestrateur ni enchaînement automatique des tests et validations.
3. Nommage incohérent : on ne maîtrise pas celui des éditeurs, et les noms auto-générés ou variables dégradent la CMDB.
4. CMDB peu fiable : la réconciliation entre ce qui est déployé et ce qui est référencé est approximative.
5. Pas de SBOM : la composition d'une application n'est pas connue précisément. Répondre à « qui utilise log4j-core ? » demande environ 2 jours d'enquête manuelle.
6. Immuabilité non garantie : rien n'empêche techniquement de remplacer un binaire après livraison, donc pas de preuve que « l'application X tournait avec cette pile à la date T ».
7. Documentation dispersée : sans gouvernance, il est difficile de retrouver quelle doc correspond à quelle version d'artefact.
8. Pas de gates de promotion : le passage dev, recette, prod repose sur des validations informelles, avec une piste d'audit partielle.

## Enjeux

1. Socle commun : Un seul investissement sert l'ensemble du portefeuille d'applications
2. Traçabilité de bout en bout : le registry devient la source unique de ce qui est déployé (nom normalisé, version, checksum, SBOM). Sans lui, le workflow déploie des artefacts dont on ne peut pas prouver l'origine.
3. Sécurité de la chaine de livraison : tout artefact passe par un point de contrôle unique (scan CVE, licences, signature éditeur, mirror avec liste blanche). C'est le point d'entrée du code externe en milieu protégé, donc l'enjeu de sécurité n°1.
4. Reproductibilité et immuabilité : le workflow ne déploie que des versions figées et référencées par leur hash. Cela permet de rejouer un déploiement à l'identique et de prouver « à la date T, l'application X tournait avec cette pile ».
5. Réduction du travail manuel et des erreurs : les déploiements enchaînés (déploiement, smoke tests, notification, réconciliation CMDB) remplacent les procédures manuelles. Le gain est surtout sur la fiabilité, pas seulement sur le temps.
6. Gouvernance et auditabilité : les gates de promotion (dev, recette, prod) et les validations humaines (change, ITSM) laissent une piste d'audit native. Cela répond aux exigences de conformité sans surcharge documentaire.
7. Réconciliation CMDB : la normalisation à l'ingestion rend les requêtes d'impact fiables (qui utilise log4j-core ?). Tant que le nommage n'est pas propre, la CMDB reste approximative.
8. Dette de nommage et migration : la normalisation des artefacts existants et le passage de l'organisation par service à l'organisation par domaine métier sont lourds. C'est le principal risque de délai, et il faut le traiter en phases avec une période de double structure.
9. Conduite du changement : l'adoption dépend des équipes applicatives, qui doivent accepter les contraintes (nommage strict, doc versionnée, approbation). Si le circuit est trop lent, elles contourneront le registry.
10. Objectifs mesurables (KPI et SLO) : sans situation initiale ni cibles chiffrées, le succès du projet ne peut pas être démontré. Les KPI mesurent le résultat (délai d'enquête, couverture SBOM), les SLO engagent le niveau de service de la plateforme (disponibilité du registry et d'Ansible, délais de synchronisation). L'état de départ doit être mesuré avant le premier lot.

### Objectifs mesurables (KPI et SLO)

| Indicateur | Type | Situation actuelle | Cible |
|---|:---:|---|---|
| Applications disposant d'un SBOM | KPI | À mesurer | À définir |
| Déploiements passant par un workflow Ansible | KPI | À mesurer | À définir |
| Artefacts avec métadonnées d'identité conformes | KPI | À mesurer | À définir |
| Taux de rapprochement registry / CMDB | KPI | À mesurer | ≥ 95 % (pressentie) |
| Délai de synchronisation registry vers CMDB | SLO | Sans objet | < 10 s (pressentie) |
| Délai d'approbation d'un artefact (par workflow CI/CD) | SLO | À mesurer | À définir par catégorie |

## Livrables

- **Dossier de flux et réseau** : flux entre registry, Ansible, CI, CMDB, Vault et cibles de déploiement, avec zones de sécurité
- **Registry**
- **Ansible**
- **CI/CD**
- **CMDB**
- **Gestion de la documentation versionnée**
- **Sécurité et conformité** : scan, analyse de risques, dossier de conformité, gestion des secrets
- **Exploitation et gouvernance** : DEX, SLO, KPI, conduite du changement

## Phasage et premiers lots

Proposition à valider. Les durées et les applications pilotes restent à définir. Les premiers lots (0, 1, 2 et 4) portent sur les trois priorités : Pipeline CI/CD, Registry et Workflows Ansible.

| Lot | Contenu | Prérequis | Sortie attendue |
|---|---|---|---|
| **0 – Cadrage** | Périmètre, répartition des applications par type (COTS, low code, dev inhouse), décideurs, mesure de l'état initial des KPI, registre des décisions | Sponsor identifié | Note de cadrage validée, situation de départ chiffrée |
| **1 – Registry** | DAT registry, organisation des dépôts, métadonnées, script d'ingestion, RBAC, sauvegarde et haute disponibilité | Lot 0 | Registry opérationnel avec 2 ou 3 applications pilotes couvrant des formes de livraison différentes |
| **2 – Workflows Ansible** | DAT Ansible, standards de rôles et playbooks, workflows Ansible chaînés, gates de promotion, déclenchement par événement, réconciliation CMDB | Lot 1 | Déploiement des applications pilotes de bout en bout via workflow Ansible |
| **3 – Sécurité de la chaîne** | Scans CVE et licences à l'ingestion, mirror avec liste blanche, gestion des secrets, signature et vérification des checksums | Lot 1 | Point de contrôle unique actif à l'ingestion |
| **4 – CI/CD** | Pipelines types par forme de livraison, stratégie de tests, versionnage | Lots 1 et 2 | Pipelines réutilisables par les équipes |
| **5 – Exploitation et gouvernance** | DEX, PRA, suivi des KPI et SLO, circuit d'approbation, conduite du changement | Lots 1 à 3 | Exploitation transférée, indicateurs suivis |
| **6 – Généralisation et migration** | Extension aux autres applications, passage de l'organisation par service au domaine métier, double structure puis retrait de l'ancienne | Lots 1 à 5 | Ensemble du périmètre couvert |

## Risques structurés

Probabilité et impact sont des estimations de départ, à valider avec les parties prenantes.

| # | Risque | Probabilité | Impact | Mitigation |
|:---:|---|:---:|:---:|---|
| 1 | Le registry ou Ansible devient un point de défaillance unique | Moyenne | Élevé | Haute disponibilité, sauvegarde avec test de restauration, mode dégradé, PRA |
| 2 | Artefact ou dépendance externe compromis (chaine de livraison) | Moyenne | Élevé | Mirror avec liste blanche, scans à l'ingestion, vérification de signature, validation sécurité |
| 3 | Contournement du registry par les équipes (adoption faible) | Élevée | Élevé | Circuit d'approbation rapide, contrôles automatisés d'abord, accompagnement, applications pilotes |
| 4 | Normalisation et migration plus longues que prévu | Élevée | Moyen | Phasage, double structure, retour arrière prévu |
| 5 | SBOM des COTS non fournis par les éditeurs | Élevée | Moyen | Exigence contractuelle aux renouvellements, reconstitution par analyse avec niveau de confiance indiqué |
| 6 | Script d'ingestion trop complexe (formats hétérogènes) | Moyenne | Moyen | Démarrer sur les formes de livraison des pilotes, élargir par itérations |
| 7 | Goulot de gouvernance (approbations lentes) | Moyenne | Moyen | Contrôles automatiques en premier, SLA par catégorie, circuit accéléré |
| 8 | Priorités et périmètre non arbitrés (pas de décideur) | Moyenne | Élevé | Sponsor désigné, critères de validation de la note |
| 9 | Succès non démontrable (pas d'état initial mesuré) | Moyenne | Moyen | Mesure de la situation de départ dans le lot 0 |
| 10 | Documentation qui diverge de l'artefact | Moyenne | Faible | URLs versionnées, contrôle de l'URL à l'approbation |

## Critères de validation de la note

La note est validée lorsque les priorités suivantes sont actées par les décideurs :

1. Pipeline CI/CD, Registry et Workflows Ansible industrialisés en premier comme socle commun indissociable.
2. Périmètre arrêté, avec la répartition des applications entre COTS, low code et dev inhouse.
3. Objectifs mesurables (KPI et SLO) fixés, avec situation de départ et cible.
4. Point de contrôle unique de la chaine de livraison à l'ingestion.
5. Premiers lots et applications pilotes désignés.

## Cas d'usage & bénéfices par rôle

| Rôle | Bénéfice | Indicateur d'impact |
|---|---|---|
| **Dév/Intégrateur** | Cycle complet env création → déploiement prod en < 30 min | Délai déploiement -70% |
| **Architecte** | Standards immuables, compliance design, traçabilité décisions | Dérives architecture = 0 |
| **BA/QA/Testeurs** | Tests automatisés intégrés au workflow, acceptance criteria exécutables | Couverture test ≥ 80%, bugs détectés -60% |
| **Exploitant/Support** | Guides opérationnels à jour, visibility incidents, feedback loop | MTTR -50%, satisfaction support +40% |
| **Compliance/Audit** | Audit trails immutables, conformité trackée, rapports auto-générés | Audit findings = 0, compliance ready |
| **Sécurité** | Scan CVE centralisé, supply chain contrôlée, secrets gérés | Couverture SBOM = 100%, vulnérabilités -80% |
| **PO/BA** | Spécifications métier versionnées, feedback cycle rapide, valeur délivrée mesurée | Time-to-market -40%, ROI clair |
| **Manager/Pilotage** | Visibilité temps réel : KPI, risques, gouvernance | Décision éclairée, governance active |
| **Ops/SRE** | Guides opérationnels générés, SLO mesurés, PRA testé | Availability ≥ 99.9%, incidents -50% |

## Démarche projet

- Organisation Agile **User Stories (US)** et **Epics** structurent la livraison
- Architecture Review Documents (ARD)
- Chaque Epic majeur produit un ARD

### Cadence

- **Sprint** : 1 semaine
- **Revue d'architecture (ARD)** : Toutes les 2 semaines ou à la fin d'une Epic
- **Rétrospective** : Fin d'Epic 

### Phasage & premiers lots

Proposition : 3 lots majeurs sur **application pilote** 

**Lot 1 – Registry**
- Ingestion artefacts, métadonnées, SBOM
- Sortie : App pilote avec artefacts tracés dans registry

**Lot 2 – CI/CD**
- Pipeline build/test/package automatisé (GitHub Actions)
- Sortie : App pilote : push → image dans registry (automatique)

**Lot 3 – Workflow Ansible de livraison**
- Promotion dev→recette→prod (Ansible)
- Gates de promotion, validations
- Sortie : App pilote déployée end-to-end via workflow Ansible

### Rôles clés

- **Product Owner** : Priorise US, valide acceptance criteria
- **Architects** : Revues ARD, compliance, risques
- **Teams** :  

### Livrables par Sprint

Chaque sprint produit :
- Code/infra 
- Paramétage
- Documentation (ARD, Guide utilisateurs ...)

