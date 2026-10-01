# SRE – Automatisations possibles par type de solution

## Légende

| Score | Signification |
|:---:|---|
| **0** | Non concerné ou impossible (code fermé) |
| **5** | Partiellement concerné (enveloppe de déploiement seulement, ou uniquement nos extensions) |
| **10** | Pleinement automatisable (100 % concerné) |

## Types de solution

- **COTS** : binaire livré, support éditeur, pas de code source. On n'agit qu'en boîte noire, depuis l'extérieur.
- **Low code** : plateforme configurée et étendue. Du code uniquement sur nos extensions, modules et configurations.
- **Dev inhouse** : tout le code est à nous. 

## Tableau

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
| Workflows Ansible chaînés (déploiement → smoke tests → notification) | 10 | 10 | 10 |
| Pipeline de build CI | 0 | 5 | 10 |
| Promotion entre environnements avec gates (dev → recette → prod) | 10 | 10 | 10 |
| Validation humaine intégrée (change, ITSM) | 10 | 10 | 10 |
| Déclenchement événementiel (webhook registry → Ansible) | 10 | 10 | 10 |
| Réconciliation CMDB après déploiement | 10 | 10 | 10 |
| Workflows métier internes aux applications (ex. circuits d'approbation) | 0 | 5 | 10 |
| **REGISTRY** | | | |
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
| Version bumping semver automatique | 0 | 5 | 10 |
| Génération des release notes | 0 | 5 | 10 |
| Signature des artefacts que nous produisons | 0 | 5 | 10 |
| Notifications de release | 10 | 10 | 10 |

## Commentaires

**COTS** : déploiement, workflows Ansible, registry, supervision, sauvegarde.

**Low code** : plutôt 5, car la chaîne qualité ne s'applique qu'aux extensions, pas à la plateforme.

**Dev inhouse** : presque tout à 10, mais tout est à construire et à maintenir.

**Workflow et registry** sont les deux blocs où les trois colonnes convergent le plus. C'est le socle commun à industrialiser en premier.

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

1. Socle commun : les trois colonnes (COTS, low code, dev inhouse) y sont à 10. Un seul investissement sert l'ensemble du portefeuille d'applications, quel que soit leur type.
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

Les cibles marquées « pressentie » viennent des travaux de conception et restent à confirmer.

| Indicateur | Type | Situation actuelle | Cible |
|---|:---:|---|---|
| Délai pour répondre à « qui utilise le composant X ? » | KPI | ~2 jours (à confirmer) | ~2 heures (pressentie) |
| Applications disposant d'un SBOM | KPI | À mesurer | À définir |
| Déploiements passant par un workflow Ansible | KPI | À mesurer | À définir |
| Artefacts avec métadonnées d'identité conformes | KPI | À mesurer | À définir |
| Taux de rapprochement registry / CMDB | KPI | À mesurer | ≥ 95 % (pressentie) |
| Délai de synchronisation registry vers CMDB | SLO | Sans objet | < 10 s (pressentie) |
| Disponibilité du registry | SLO | Sans objet | À définir |
| Disponibilité d'Ansible | SLO | Sans objet | À définir |
| Délai d'approbation d'un artefact | SLO | À mesurer | À définir par catégorie |

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

Proposition à valider. Les durées et les applications pilotes restent à définir. Les premiers lots (0, 1 et 2) portent sur les deux priorités : registry et workflows.

| Lot | Contenu | Prérequis | Sortie attendue |
|---|---|---|---|
| **0 – Cadrage** | Périmètre, répartition des applications par type (COTS, low code, dev inhouse), décideurs, mesure de l'état initial des KPI, registre des décisions | Sponsor identifié | Note de cadrage validée, situation de départ chiffrée |
| **1 – Registry** | DAT registry, organisation des dépôts, métadonnées, script d'ingestion, RBAC, sauvegarde et haute disponibilité | Lot 0 | Registry opérationnel avec 2 ou 3 applications pilotes couvrant des formes de livraison différentes |
| **2 – Workflows (Ansible)** | DAT Ansible, standards de rôles et playbooks, workflows chaînés, gates de promotion, déclenchement par événement, réconciliation CMDB | Lot 1 | Déploiement des applications pilotes de bout en bout via workflow |
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

1. Registry et workflows industrialisés en premier, comme socle commun.
2. Périmètre arrêté, avec la répartition des applications entre COTS, low code et dev inhouse.
3. Objectifs mesurables (KPI et SLO) fixés, avec situation de départ et cible.
4. Point de contrôle unique de la chaine de livraison à l'ingestion.
5. Premiers lots et applications pilotes désignés.

## Réserves

Les scores 5 sont des jugements à valider avec l'expérience des produits en place, notamment sur le comportement réel des plateformes low code (extensions, SBOM, métriques) et sur ce que les COTS exposent (logs, snapshots).
