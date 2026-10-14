# Sécurité et bonnes pratiques du pipeline CI/CD

Ce document confronte le workflow `.github/workflows/ci.yml` aux pratiques de référence 2025-2026 pour les chaînes CI/CD. Il distingue trois choses : **ce que le pipeline fait déjà**, **l'écart**, et **la cible** à atteindre. Les extraits « cible » ne sont pas encore appliqués au workflow.

Le déroulé du pipeline est dans [pipeline-build-promotion.md](pipeline-build-promotion.md) ; la gouvernance des artefacts est dans [registry/README.md](../registry/README.md).

## Référentiels

| Référentiel | Ce qu'on en retient |
|---|---|
| OWASP Top 10 CI/CD Security Risks | dix familles de risques, de l'insuffisance de contrôle de flux (CICD-SEC-1) au manque de journalisation (CICD-SEC-10) |
| NIST SP 800-204D | intégrer la sécurité de la chaîne d'approvisionnement logicielle dans le pipeline : détection de secrets, analyse des dépendances, contrôles automatiques de chaque contribution |
| CISA / NSA, « Defending CI/CD Environments » | durcir les identités, isoler les builds, journaliser |
| ANSSI (recommandations DevSecOps) | traiter la chaîne CI/CD de production comme un poste d'administration, signer les artefacts le plus tôt possible et vérifier la signature au déploiement |
| SLSA v1.1 | niveaux de garantie sur la production d'artefacts (provenance, signature, isolation du build) |

## Les risques OWASP face à factice

| Risque | Situation dans factice | Niveau |
|---|---|---|
| CICD-SEC-1 Contrôle de flux insuffisant | Fusion par demande de fusion, contrôle `build` ; production manuelle, bloquée par `change-gate` (changement ITSM approuvé par un humain distinct du demandeur). Pas de relecteur GitHub (décision 16). | partiel |
| CICD-SEC-2 Gestion des identités et accès | Trois comptes Nexus cloisonnés. Mots de passe longue durée. | partiel |
| CICD-SEC-3 Chaîne de dépendances | `npm ci` sur lockfile. Aucun scan des dépendances ni de l'image. Actions épinglées par étiquette. | à traiter |
| CICD-SEC-4 Exécution de pipeline empoisonné | Runner auto-hébergé exécutant le code des demandes de fusion. | à traiter |
| CICD-SEC-5 Contrôles d'accès insuffisants au pipeline | Pas de bloc `permissions:` : le jeton hérite des droits par défaut du dépôt. | à traiter |
| CICD-SEC-6 Hygiène des identifiants | Secrets GitHub, jamais en argument de commande. Pas de rotation documentée. | partiel |
| CICD-SEC-7 Configuration système non sûre | Runner persistant, partagé avec les tiers de production. | à traiter |
| CICD-SEC-8 Services tiers non gouvernés | Actions tierces (`actions/*`) uniquement, épinglées par étiquette. | partiel |
| CICD-SEC-9 Intégrité des artefacts | Contrôle de provenance du commit, déploiement par empreinte, SBOM. Pas de signature. | partiel |
| CICD-SEC-10 Journalisation et visibilité | Événement de déploiement et journal d'audit Nexus. Pas d'alerte sur les échecs de pipeline. | partiel |

## 1. Droits minimaux du jeton `GITHUB_TOKEN`

**Pourquoi.** Le jeton du workflow s'ouvre par défaut avec les droits configurés au niveau du dépôt, souvent trop larges. Restreindre ses droits est la mesure à plus fort effet sur la sécurité d'un workflow : un job compromis ne peut alors rien écrire dans le dépôt.

**État.** Aucun bloc `permissions:`.

**Cible.**

```yaml
permissions:
  contents: read        # par défaut pour tout le workflow

jobs:
  build:
    permissions:
      contents: read
  # élargir job par job, seulement si le job écrit réellement
```

Régler aussi le dépôt sur « permissions en lecture seule par défaut » (Settings, Actions, General).

## 2. Épingler les actions par empreinte de commit

**Pourquoi.** Une étiquette (`@v4`) peut être déplacée par son mainteneur ; seul un SHA complet est immuable. C'est la recommandation officielle de GitHub pour les actions tierces.

**État.** `actions/checkout@v4`, `actions/setup-node@v4`.

**Cible.**

```yaml
- uses: actions/checkout@<sha-complet-de-40-caractères> # v4.x.y
```

Faire maintenir ces empreintes par Dependabot ou Renovate, qui proposent des mises à jour relues en demande de fusion.

## 3. Exécution de pipeline empoisonné et injection

**Pourquoi.** Un workflow déclenché par une demande de fusion exécute du code de la branche. Si ce workflow dispose de secrets ou d'un runner qui touche la production, la demande de fusion devient un vecteur d'attaque.

**État.** Les secrets Nexus ne sont utilisés que dans des étapes exclues des demandes de fusion (`github.event_name != 'pull_request'`), ce qui est bien. Aucune interpolation de données d'événement dans un `run:` n'est utilisée à ce jour, hors `github.sha` et `github.run_number`, non contrôlables par un tiers.

**Règles à garder.**

- `pull_request` sans secrets ; ne jamais utiliser `pull_request_target` avec un checkout du code de la demande de fusion ;
- ne jamais interpoler `${{ github.event.* }}` (titre de PR, nom de branche, message de commit) directement dans un `run:` : passer par une variable d'environnement ;
- relire toute modification de `.github/workflows/` avec le même soin que du code d'infrastructure ;
- ajouter un contrôle automatique du workflow avec `actionlint` et un audit de sécurité des workflows avec `zizmor`.

## 4. Runner auto-hébergé

**Pourquoi.** Un runner persistant conserve l'état d'un job à l'autre (fichiers, variables, caches). Du code malveillant exécuté une fois peut s'y installer. Les sources de référence déconseillent les runners auto-hébergés sur dépôt public et recommandent des runners éphémères.

**État.** Le runner est installé sur l'hôte qui porte aussi les tiers de production (voir [zones-securite.md](../../1-fondations/zones-securite.md)). Aucun runner n'est encore enregistré (voir les limites connues de [Docs/README.md](../../README.md)).

**Cible, par ordre d'effort croissant.**

1. Dépôt **privé** uniquement ; aucune demande de fusion externe n'exécute de workflow sur ce runner.
2. Compte système **dédié**, sans droits d'administration, sans accès aux fichiers des autres comptes.
3. Mode **éphémère** (`config.sh --ephemeral`) : un job par enregistrement, puis désinscription. Attention : un runner éphémère sur le même disque, le même démon Docker et les mêmes caches n'est pas pour autant un environnement propre.
4. Séparer l'hôte de **build** de l'hôte de **production**. À défaut, documenter le risque comme accepté pour la maquette.

## 5. Concurrence et délais

**Pourquoi.** Deux déploiements simultanés sur le même environnement se disputent les ports, la base et les fichiers ; un job bloqué occupe le runner indéfiniment.

**Cible.**

```yaml
concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: false      # ne jamais interrompre un déploiement en cours

jobs:
  deploy-production:
    timeout-minutes: 20
    concurrency:
      group: deploy-production
      cancel-in-progress: false
```

## 6. Environnement `production` et règles de dépôt

**Pourquoi.** Une approbation humaine n'a de valeur que si elle est obligatoire et indépendante.

**État.** `environment: production` est déclaré dans le workflow. Les réglages côté GitHub (relecteurs, restrictions) ne sont pas décrits dans le dépôt.

**Cible, côté GitHub (Settings, Environments, `production`).**

- **relecteurs obligatoires** (jusqu'à six personnes ou équipes) ;
- **interdire l'auto-approbation** : celui qui lance le déploiement ne peut pas l'approuver ;
- limiter les branches autorisées à `main` ;
- porter les secrets de production **dans l'environnement**, pas au niveau du dépôt.

**Règles de dépôt (rulesets) sur `main`.** Contrôle de statut `build` obligatoire, historique linéaire, pas de poussée directe ni forcée, relecture obligatoire ; file de fusion (*merge queue*) à envisager si le volume de demandes de fusion augmente. Les rulesets s'empilent et s'appliquent à plusieurs branches, contrairement à la protection de branche seule. Ces réglages portent la vérification de provenance de `promote.sh`, qui refuse un commit absent de `origin/main`.

## 7. Analyse des vulnérabilités et des dépendances

**Pourquoi.** Le SBOM décrit le contenu de l'image mais ne dit rien de sa sûreté. Sans analyse, une image vulnérable est promue aussi facilement qu'une autre.

**État.** SBOM produit (`scripts/nexus/gen-sbom.sh`) ; aucune analyse. Cet écart est déjà noté dans la spécification Nexus.

**Cible.**

| Contrôle | Outil possible | Moment |
|---|---|---|
| Dépendances Node.js | `npm audit`, OSV-Scanner | `build` |
| Image | Trivy ou Grype | `build`, avant publication du candidat |
| Secrets dans le code | gitleaks | demande de fusion |
| Workflows | actionlint, zizmor | demande de fusion |

Seuil de blocage conseillé : `CRITICAL` et `HIGH` avec correctif disponible (`--severity CRITICAL,HIGH --ignore-unfixed --exit-code 1`).

**Exceptions.** Documenter une vulnérabilité non exploitable avec un **VEX** (document structuré, versionné, relu) plutôt qu'avec un fichier d'ignorés opaque. Nommer le fichier du SBOM avec l'**empreinte** de l'image et non une version, pour qu'une re-étiquette ne le rende pas orphelin.

**Réanalyse.** Un SBOM permet de réanalyser les releases déjà en production contre les nouvelles vulnérabilités, sans reconstruire : planifier cette réanalyse (hebdomadaire).

## 8. Signature, provenance et vérification

**Pourquoi.** Le contrôle de provenance actuel prouve que le commit est sur `main`. Il ne prouve pas que l'image présente dans Nexus est bien celle que le workflow a construite : quelqu'un ayant les droits d'écriture sur le registry pourrait la remplacer.

**État.** Déploiement par empreinte, SBOM, manifeste, comptes cloisonnés. Pas de signature, pas d'attestation.

**Cible.**

1. **Signer l'image par empreinte** dans le job `build`, par Sigstore/cosign en mode sans clé (identité du workflow via OIDC) ou par attestation GitHub.
2. **Attester la provenance** (format SLSA) et le **SBOM** (CycloneDX) en les attachant à l'image.
3. **Vérifier au déploiement**, avant `ansible-playbook` :

```bash
cosign verify \
  --certificate-identity-regexp '^https://github.com/<org>/factice/\.github/workflows/ci\.yml@refs/heads/main$' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  <hôte release>/factice.app/factice@<empreinte>
```

**Où se situe factice sur l'échelle SLSA ?**

| Niveau | Exigence | Factice |
|---|---|---|
| L1 | provenance générée automatiquement et disponible | partiel : le manifeste porte commit et version, mais n'est pas au format SLSA |
| L2 | provenance signée par la plateforme de build, vérifiable | atteignable avec une attestation GitHub |
| L3 | build isolé, protégé contre la falsification par un autre job | hors de portée avec un runner persistant partagé |

**Points d'attention.** La signature sans clé dépend des services publics Sigstore (disponibilité, journal de transparence public) ; une instance privée ou une clé gérée est l'alternative si cette dépendance est inacceptable. Signer sans vérifier ne sert à rien : la vérification au déploiement fait partie de la mesure.

## 9. Identifiants

**Pourquoi.** Un mot de passe longue durée qui fuit reste valable jusqu'à rotation.

**État.** Trois mots de passe de comptes de service Nexus, stockés comme secrets GitHub et dans Bitwarden.

**Cible.** Une date de rotation par secret ; des secrets de production portés par l'environnement protégé ; des jetons à portée limitée ou à durée courte chaque fois que le registry le permet ; aucune valeur de secret dans les journaux (le masquage de GitHub ne couvre que les valeurs qu'il connaît).

## 10. Traçabilité de la construction

- Image de base épinglée par **empreinte** (`FROM node:20-alpine@sha256:...`) et non par étiquette, mise à jour par Renovate.
- Étiquettes OCI sur l'image : `org.opencontainers.image.revision` (commit), `org.opencontainers.image.source` (dépôt), `org.opencontainers.image.version`. Elles relient une image en production à son commit sans consulter Nexus.
- `npm ci` sur lockfile versionné (déjà le cas) ; remplacer `--only=production` par `--omit=dev`.

## 11. Mesure de la livraison

Les quatre mesures DORA se lisent à partir des données du dépôt : fréquence de déploiement et délai de livraison (workflow), taux d'échec des changements et temps de restauration (événements de déploiement, résultat `reussi`, `echoue` ou `retour-arriere`). Le rapport DORA 2025 observe que l'usage de l'IA accroît le débit de livraison mais aussi l'instabilité : ne pas lire la fréquence seule, suivre la stabilité à côté.

## Plan d'adoption suggéré

| Ordre | Mesure | Effort |
|---|---|---|
| 1 | `permissions:` minimales, `timeout-minutes`, `concurrency` | faible |
| 2 | Actions épinglées par SHA + Dependabot | faible |
| 3 | Relecteurs obligatoires et interdiction d'auto-approbation sur `production` ; rulesets | faible, côté GitHub |
| 4 | Scan des dépendances et de l'image avec seuil bloquant | moyen |
| 5 | Signature et vérification au déploiement | moyen |
| 6 | Runner éphémère ou séparé de la production | élevé |

## Références

- OWASP, [Top 10 CI/CD Security Risks](https://owasp.org/projects/top-10-cicd-security-risks) et [CI/CD Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html)
- NIST, [SP 800-204D](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-204D.pdf)
- CISA / NSA, [Defending CI/CD Environments](https://media.defense.gov/2023/Jun/28/2003249466/-1/-1/0/CSI_DEFENDING_CI_CD_ENVIRONMENTS.PDF)
- SLSA, [exigences v1.1](https://slsa.dev/spec/v1.1/requirements)
- GitHub, [Deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments), [About protected branches](https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)
- Runners : [Praetorian](https://www.praetorian.com/blog/self-hosted-github-runners-are-backdoors/), [Sysdig](https://www.sysdig.com/blog/how-threat-actors-are-using-self-hosted-github-actions-runners-as-backdoors)
- Durcissement : [StepSecurity](https://www.stepsecurity.io/blog/github-actions-security-best-practices)
- DORA : [synthèse du rapport 2025](https://www.scrum.org/resources/blog/dora-report-2025-summary-state-ai-assisted-software-development)
