# TODO — Documentation factice : sujets à retravailler

Audit du 2026-10-02 des documents non encore retravaillés de `Docs/1-fondations/` et `Docs/2-pipeline-livraison/` (hors `registry/` et hors `sre*.md`, déjà faits), confrontés à l'état de l'art 2025-2026.

Légende : **P1** = écart avec la réalité ou risque réel, **P2** = pratique de référence manquante, **P3** = amélioration.

---

## 0. Corrections factuelles — faites le 2026-10-02

- [x] `flux-et-reseau.md` réécrit à partir de `ci.yml` (promotion automatique sur `main`, Ansible lancé par le workflow, pas de webhook entrant, CMDB optionnelle).
- [x] Incohérences Nexus « Internet » / « réseau privé », « deux tiers », « mode rapide » supprimées avec la réécriture.
- [x] `zones-securite.md` écrit (zones, frontières de confiance, isolation, limites).
- [x] « Mac Mini » remplacé par « hôte macOS » dans `Docs/` et dans le commentaire de `roles/github_runner/defaults/main.yml`.
- [x] Liens relatifs cassés corrigés (`trunk-based`, `nexus/`, `flux-cicd.md`, `architecture.md`, `contrat-deploy-stack.md`, documents Nexus et automatisation) ; chemin de la spec Nexus corrigé dans `ci.yml`, `provision-nexus.yml` et `roles/nexus/defaults/main.yml`.
- [x] `ci-cd/README.md`, `1-fondations/README.md` reformulés ; `standards-et-guidelines.md` aligné sur le vrai workflow (plus de `latest`, `ubuntu-latest`, `checkout@v3`).
- [x] Documenté, workflow inchangé (décision ouverte : corriger le workflow ou accepter ce comportement) : `deploy-production` dépend de `promote`, donc un lancement manuel en production reconstruit et republie une nouvelle release au lieu de déployer une release déjà promue. `trunk-based.md` et `pipeline-build-promotion.md` disent l'inverse. Soit corriger le workflow, soit la doc.
- [x] `isolation-et-reseau.md` réécrit : plus de syntaxe UFW, TLS décrit tel qu'il est (HTTP), ports et réseau Docker réels.

---

## 1. CI/CD — `ci-cd/pipeline-build-promotion.md` et `ci.yml`

> **Statut (2026-10-02)** : tout §1 est **documenté** dans `ci-cd/securite-pipeline.md` (état, écart, cible) et `ci-cd/pipeline-build-promotion.md` (« Écarts connus », retour arrière, graphe de dépendances corrigé). Les cases restent ouvertes tant que `ci.yml` n'est pas modifié : la consigne de cette étape était « juste la doc ».

État de l'art : durcissement des workflows GitHub Actions, OWASP Top 10 CI/CD Security Risks, NIST SP 800-204D, guide CISA/NSA, recommandations ANSSI (la chaîne CI/CD de production = poste d'administration).

Constat sur `ci.yml` (161 lignes) : aucun bloc `permissions:`, aucun `concurrency:`, aucun `timeout-minutes:`, actions épinglées par tag (`@v4`), aucun scan de vulnérabilités, aucune signature, aucune attestation de provenance.

- [ ] **P1 — `permissions:` minimales.** Déclarer `permissions: contents: read` au niveau workflow, élargir par job seulement si nécessaire. C'est le réglage à plus fort impact selon toutes les sources consultées. Documenter le principe dans la page.
- [ ] **P1 — Épingler les actions par SHA complet** (`actions/checkout@<sha> # v4.x.y`), géré par Dependabot/Renovate. Recommandation officielle GitHub : seul un SHA est immuable, un tag peut être déplacé.
- [ ] **P1 — Runner auto-hébergé non éphémère.** Risque documenté (Praetorian, Sysdig) : un runner persistant garde l'état d'un job à l'autre ; le code d'une PR s'exécute sur l'hôte qui porte aussi la production. À traiter : dépôt privé uniquement, workflows de PR sans secrets, mode `--ephemeral` / JIT, utilisateur dédié sans droits d'administration, séparation runner de build / hôte de production (ou le documenter comme risque accepté). Note : le dépôt actuel n'a pas encore de runner enregistré.
- [ ] **P1 — Poisoned Pipeline Execution (CICD-SEC-4).** Déclencheurs `pull_request` sans secrets ; jamais `pull_request_target` avec checkout du code de la PR ; pas d'interpolation `${{ github.event.* }}` dans un `run:` (injection de script). Ajouter un audit de ce type avec `zizmor` ou `actionlint`.
- [ ] **P2 — `concurrency:`** par environnement (un seul déploiement à la fois, sans annuler un déploiement de production en cours) et **`timeout-minutes:`** par job.
- [ ] **P2 — Protection de l'environnement `production`** (GitHub Environments) : relecteurs obligatoires, **interdire l'auto-approbation** (l'initiateur ne peut pas approuver), restriction aux branches autorisées, secrets de production portés par l'environnement et non par le dépôt.
- [ ] **P2 — Règles de dépôt (rulesets)** plutôt que protection de branche seule : contrôles de statut obligatoires, historique linéaire, pas de force-push, éventuellement merge queue. Aligner avec `trunk-based.md` et la vérification de provenance de `promote.sh`.
- [ ] **P2 — Scan de l'image et des dépendances** avant promotion (Trivy ou Grype ; `--severity CRITICAL,HIGH --exit-code 1 --ignore-unfixed`), détection de secrets, `npm audit`/OSV-Scanner. Documenter la politique d'exception (VEX plutôt que fichier d'ignorés).
- [ ] **P2 — Signature et provenance.** Passer de « SBOM + vérification du commit » à : signature de l'image **par empreinte** (cosign, signature par identité de workflow OIDC) ou attestation GitHub, attestation de provenance SLSA, SBOM attaché comme attestation, **vérification au déploiement** (`cosign verify --certificate-identity… --certificate-oidc-issuer…`). Situer factice sur l'échelle SLSA Build L1 → L3 et dire où elle s'arrête : SLSA L3 suppose des builds isolés, ce qu'un runner persistant n'offre pas. Tenir compte du fait que la signature keyless dépend de services publics Sigstore (ou prévoir une instance privée / clé gérée).
- [ ] **P2 — Identifiants.** Remplacer les mots de passe longue durée des comptes Nexus par des jetons à portée limitée / OIDC lorsque c'est possible ; masquer et journaliser l'usage ; rotation documentée (voir aussi §2 secrets).
- [ ] **P3 — Traçabilité du build.** Reproductibilité (image de base épinglée par empreinte, `npm ci`, cache maîtrisé), étiquettes OCI (`org.opencontainers.image.revision`, `source`) pour relier image ↔ commit.
- [ ] **P3 — Mesure.** Reprendre les 4 métriques DORA du dépôt et nommer explicitement l'instabilité (taux d'échec, temps de restauration). Le rapport DORA 2025 note que l'adoption de l'IA augmente le débit mais aussi l'instabilité : justifie de garder des garde-fous (tests, revue) plutôt que d'accélérer seulement.
- [ ] **P3 — Retour arrière.** Détailler la procédure testée (redéploiement d'une empreinte précédente), le temps cible, et la limite : un retour arrière d'image ne défait pas une migration de base de données (voir §2).

---

## 2. Orchestration — `orchestration/workflow-ansible.md` et `deploy-stack-contract.md`

> **Statut (2026-10-02)** : tout §2 est **documenté** dans `orchestration/bonnes-pratiques-ansible.md`, `workflow-ansible.md` (vault en clair, événement émis par le workflow, particularités macOS) et `deploy-stack-contract.md` (« Écarts et évolutions »). Aucun code modifié. La migration `docker_compose_v2` est déjà faite dans le code et la doc est exacte.

État de l'art : ansible-lint (profil `production`), Molecule (converge + idempotence + verify), mode `--check --diff`, `no_log`, gestion externe des secrets, déploiement sans interruption, migrations de base « expand / contract ».

- [ ] **P1 — Migration `docker_compose` → `docker_compose_v2`** (déjà au TODO racine) : à refléter dans le contrat de `deploy_stack`, qui cite `docker_compose_v2` alors que les rôles utilisent encore l'ancien module. Vérifier que la doc décrit bien l'état réel.
- [ ] **P1 — Tests de rôles avec Molecule** (déjà au TODO pour `roles/nexus`) : étendre à `deploy_stack` et `factice`. Cycle attendu : `converge` → seconde exécution vérifiant `changed=0` → `verify`. Limite à documenter : les tiers natifs macOS (Homebrew, LaunchAgent) ne se testent pas dans un conteneur Linux ; dire ce qui est testé où.
- [ ] **P2 — `ansible-lint` au niveau de profil `production`** dans la CI (le standard actuel dit seulement « ansible-lint »). Ajouter `yamllint`, noms de modules complets (FQCN), `ansible-playbook --syntax-check` et un `--check --diff` avant le déploiement réel.
- [ ] **P2 — Contrat du rôle vérifié par machine** : `meta/argument_specs.yml` pour `deploy_stack` (le tableau de variables de `deploy-stack-contract.md` deviendrait la source de vérité, validée à l'exécution).
- [ ] **P2 — Secrets.** Ansible Vault suffit pour une petite équipe ; documenter ses limites (mot de passe du coffre dans `~/.factice-vault-pass`, pas de rotation, pas d'audit) et l'option « mot de passe du coffre ou secrets lus à l'exécution depuis un gestionnaire externe » (Bitwarden Secrets Manager dispose d'un plugin de recherche Ansible). Exiger `no_log: true` sur toute tâche manipulant un secret. Documenter le fichier `.env` (mode `0600`) déposé sur l'hôte et son risque.
- [ ] **P2 — Chiffrer réellement `vault.yml`** : la doc admet qu'il contient des valeurs de remplacement en clair. Ajouter un contrôle en CI (refuser un `vault.yml` non chiffré).
- [ ] **P2 — Stratégie de déploiement.** Aujourd'hui : recréation du conteneur, donc interruption brève. Décrire l'état de l'art à l'échelle d'un hôte unique (déploiement séquentiel avec contrôle de santé et retour arrière automatique ; bleu/vert derrière le reverse proxy ; ce qui est hors périmètre sans orchestrateur) et expliciter le choix retenu.
- [ ] **P2 — Migrations de base de données.** Pour que le retour arrière par empreinte soit sûr : modèle « expand / contract » (changements compatibles dans les deux sens, suppression différée), sauvegarde avant migration, et dire qui exécute la migration (Ansible ou l'application au démarrage).
- [ ] **P2 — Contrôles de santé** : distinguer *liveness* et *readiness*, définir un `HEALTHCHECK` dans l'image/Compose, et ne pas se contenter d'un `curl /health` de fin de pipeline (le workflow le fait sur `localhost`, donc seulement depuis le runner).
- [ ] **P3 — Dérive de configuration** : un passage planifié en `--check` pour détecter les écarts entre l'hôte et le dépôt (`changed` non nul hors déploiement = dérive).
- [ ] **P3 — `workflow-ansible.md`** : réduire les détails d'implémentation propres à macOS (brew, `launchctl`, `host.docker.internal`) à une section « particularités de la plateforme » pour que le document reste lisible comme un patron générique ; ajouter pour chaque tier une table « ce qui est vérifié / par quoi ».

---

## 3. Fondations — `1-fondations/`

> **Statut (2026-10-02)** : §3 est **documenté** : `flux-et-reseau.md` (DFD, frontières, chiffrement), `zones-securite.md` (accès d'administration, exposition), `modele-menaces.md` (STRIDE), `4-securite/isolation-et-reseau.md` (ports, pf, TLS). Règles `pf` et liaisons d'écoute : décrites comme cibles, pas rédigées ni appliquées. La matrice de flux « de → vers » est dans `flux-et-reseau.md` sans colonne « justification ».

État de l'art : modélisation des menaces (diagramme de flux de données + STRIDE), segmentation par défaut-refus, principes Zero Trust (NIST SP 800-207), micro-segmentation (guide CISA 2025).

- [ ] **P1 — Réécrire `flux-et-reseau.md`** à partir d'un **diagramme de flux de données** réel (Mermaid) : acteurs, processus, magasins de données, **frontières de confiance** (GitHub ↔ runner ↔ Nexus ↔ hôte ↔ Internet), protocoles, ports et authentification de chaque flux. Source de vérité : `ci.yml`, `inventory/`, Caddyfile, Compose.
- [ ] **P1 — Écrire `zones-securite.md`** : matrice de flux « de → vers : port, protocole, authentification, chiffrement, justification », politique par défaut « tout refusé sauf liste explicite », isolation intégration/production (réseaux Docker distincts, bases, utilisateurs, secrets — déjà partiellement vrai, à démontrer).
- [ ] **P2 — Modèle de menaces STRIDE** sur ces flux, avec pour chaque menace : mesure en place, mesure manquante, risque accepté. Lier aux risques OWASP CI/CD (§1).
- [ ] **P2 — TLS et exposition.** Le périmètre exclut TLS (HTTP local). Documenter explicitement ce qui circule en clair, sur quel segment, et ce qui change dès qu'un flux sort de l'hôte (Caddy gère le TLS automatique, à mentionner comme évolution).
- [ ] **P2 — Pare-feu hôte et liaisons d'écoute** : PostgreSQL lié à `127.0.0.1` uniquement, ports publiés limités à l'interface voulue, règles `pf` documentées.
- [ ] **P3 — Accès d'administration** : qui peut exécuter Ansible, depuis où, avec quelle authentification ; traiter le poste d'exécution comme un actif sensible.

---

## 4. Transversal

- [x] Après réécriture, mettre à jour `Docs/INDEX.md` et `Docs/README.md` (liens, descriptions) et relancer une vérification de liens relatifs sur tout `Docs/`.
- [x] Ajouter dans chaque document retravaillé une section « Références » (sources normatives) pour que les choix soient traçables.
- [x] Proposé (AC12 à AC17, « pas encore applicables » dans `Docs/README.md`) ; à valider : décider si les contrôles de §1 et §2 (lint, scan, signature, vérification) deviennent des critères d'acceptation AC12+ dans `Docs/README.md`.

---

## Sources consultées (2026-10-02)

- Durcissement GitHub Actions : [StepSecurity — 7 best practices](https://www.stepsecurity.io/blog/github-actions-security-best-practices), [Stingrai — checklist 2026](https://www.stingrai.io/blog/github-actions-security-checklist), [secure-pipelines — guide](https://secure-pipelines.com/ci-cd-security/github-actions-security-definitive-guide/), [KodeKloud — Security hardening](https://notes.kodekloud.com/docs/GitHub-Actions/Security-Guide/Security-hardening-for-GitHub-Actions)
- Runners auto-hébergés : [Praetorian — runners as backdoors](https://www.praetorian.com/blog/self-hosted-github-runners-are-backdoors/), [Sysdig — runners as backdoors](https://www.sysdig.com/blog/how-threat-actors-are-using-self-hosted-github-actions-runners-as-backdoors), [secure-pipelines — securing runners](https://secure-pipelines.com/github-actions/securing-github-actions-runners/)
- OWASP : [Top 10 CI/CD Security Risks](https://owasp.org/projects/top-10-cicd-security-risks), [CI/CD Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/CI_CD_Security_Cheat_Sheet.html)
- SLSA : [SLSA v1.1 requirements](https://slsa.dev/spec/v1.1/requirements), [niveaux SLSA v1.0](https://slsa.dev/spec/v1.0/levels)
- Signature : [Security Boulevard — Cosign et Sigstore (2026)](https://securityboulevard.com/2026/09/signing-and-verifying-container-images-with-cosign-and-sigstore/), [Sigstore keyless avec GitHub OIDC](https://www.qcecuring.com/blog/sigstore-cosign-keyless-github-actions)
- Scan et SBOM : [Trivy / Grype en CI](https://www.systemshardening.com/articles/cicd/container-vulnerability-scanning-ci/), [comparatif d'outils SBOM](https://secure-pipelines.com/ci-cd-security/sbom-tools-compared-syft-trivy-cyclonedx-cli/)
- Gouvernance GitHub : [Deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments), [About protected branches](https://docs.github.com/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)
- Normes : [NIST SP 800-204D](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-204D.pdf), [CISA/NSA — Defending CI/CD](https://media.defense.gov/2023/Jun/28/2003249466/-1/-1/0/CSI_DEFENDING_CI_CD_ENVIRONMENTS.PDF), [Wavestone — CI/CD (ANSSI)](https://www.riskinsight-wavestone.com/en/2025/09/ci-cd-the-new-cornerstone-of-the-information-system/), [NIST SP 800-207 Zero Trust](https://nvlpubs.nist.gov/nistpubs/specialpublications/NIST.SP.800-207.pdf), [CISA — micro-segmentation](https://www.cisa.gov/sites/default/files/2025-07/ZT-Microsegmentation-Guidance-Part-One_508c.pdf)
- Ansible : [Test des rôles (check, lint, Molecule)](https://oneuptime.com/blog/post/2026-07-24-testing-ansible-roles/view), [Molecule 2026](https://computingforgeeks.com/ansible-molecule-testing/), [Secrets Ansible](https://infisical.com/blog/ansible-secrets), [Bitwarden — intégration Ansible](https://bitwarden.com/help/ansible-integration/)
- Déploiement : [Docker Compose sans interruption](https://sergeyku9nov.medium.com/zero-downtime-orchestration-with-docker-compose-rolling-blue-green-and-canary-deployments-b56ece457d9d), [Progressive delivery](https://www.getunleash.io/blog/blue-green-deployment-vs-progressive-delivery)
- DORA : [Rapport DORA 2025 — synthèse](https://www.scrum.org/resources/blog/dora-report-2025-summary-state-ai-assisted-software-development), [RedMonk](https://redmonk.com/rstephens/2025/12/18/dora2025/)

Limites : synthèse issue de recherches web (blogs et documentation, pas de lecture intégrale des normes). Les points `argument_specs.yml`, `zizmor`/`actionlint`, expand/contract et l'étiquetage OCI viennent de ma connaissance générale et n'ont pas été vérifiés par ces recherches : à confirmer avant de les graver dans les documents.

---

## Nouveaux constats (relecture du code, 2026-10-02)

- `deploy-production` : un lancement manuel reconstruit et republie ; la production reçoit l'empreinte de cette exécution. Aucune entrée « empreinte » pour redéployer une ancienne release.
- `deploy-integration` se déclenche aussi lors d'un lancement manuel depuis `main` (`github.ref == 'refs/heads/main'`).
- `deploy-factice-production.yml` : tâche `pause` interactive suivie d'un `assert` ; sur un runner sans terminal, comportement à vérifier. L'environnement GitHub `production` porte déjà l'approbation.
- Le script `lint` existe mais l'analyseur n'est pas une dépendance ; la CI n'exécute que `npm test`.
- `vault.yml` en clair (`changeme-*`).
- Port du conteneur App publié sur toutes les interfaces ; Caddy en `http://:PORT` ; un seul réseau Docker `factice-network` pour les deux environnements.
- Création de l'utilisateur PostgreSQL par `shell` avec le mot de passe en ligne de commande, `|| true` et `ignore_errors` ; l'utilisateur est propriétaire de la base.
- `Docs/4-securite/secrets-et-credentials.md` : exemples obsolètes (`ubuntu-latest`, `NEXUS_USERNAME`), une note d'état réel a été ajoutée en tête ; réécriture à faire.
