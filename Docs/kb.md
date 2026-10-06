# Base de connaissances

Une fiche par problème rencontré : symptôme, cause, correctif, et le commit ou le run où il est apparu. À ajouter à la fin, jamais réécrite (une fiche fausse est corrigée par une nouvelle fiche qui la remplace). Les fiches sont lisibles sur github.com, chacune avec un lien permanent par ancre.

Format : `KB-NNN`, titre, date, composant. Une ligne **ITSM** donne l'incident (`INC-AAAA-NNNN`) quand le pipeline en a ouvert un.

## Règle : chaque incident ou correctif crée une fiche, dans le même push

1. Un déploiement en échec ouvre un incident dans l'ITSM (étape « Ouvrir un incident ITSM » de `ci.yml`).
2. Le correctif est un commit `fix…` qui ajoute la fiche `KB-NNN` ici. Le job `kb-check` ([scripts/kb/check-kb.sh](../scripts/kb/check-kb.sh)) échoue sinon. Dérogation : trailer `KB: KB-NNN` (fiche existante) ou `KB: non-applicable` avec la raison dans le message.
3. L'incident est rattaché à la fiche (`itsm.sh kb INC-… KB-NNN`) puis clos ; l'ITSM refuse la clôture en succès sans fiche.

Décision 14 de [decisions.md](decisions.md).

---

## KB-001 · Ansible : « Failed to import the required Python library (requests) »

- **Date** : 2026-10-05 · **Composant** : Ansible, runner
- **Symptôme** : le job `deploy-integration` échoue sur la tâche Docker avec `Failed to import the required Python library (requests) on macmini's Python /Library/Developer/CommandLineTools/usr/bin/python3`.
- **Cause** : l'inventaire fixait `ansible_python_interpreter=/usr/bin/python3`, le Python des Command Line Tools, qui n'a ni `requests` ni `docker`, requis par `community.docker`.
- **Correctif** : pointer sur le Python d'Ansible installé par Homebrew : `ansible_python_interpreter=/opt/homebrew/opt/ansible/libexec/bin/python` (`inventory/hosts`). Vérifier : `python -c 'import requests, docker'`.
- **Origine** : run 37323954890 ; correctif `1b679f4`.

## KB-002 · Ansible : une variable de `group_vars/<groupe>.yml` n'est jamais définie

- **Date** : 2026-10-05 · **Composant** : Ansible, inventaire
- **Symptôme** : `docker_host`, `docker_bin` et `nexus_install_dir` sont `undefined` alors qu'ils sont écrits dans `inventory/group_vars/local.yml`. Les modules Docker visent `/var/run/docker.sock` (lien vers Docker Desktop, arrêté) : `Error connecting: ... Connection refused`.
- **Cause** : un dossier `group_vars/local/` (contenant `vault.yml`) existait à côté du fichier `local.yml`. Ansible ne charge que le dossier ; le fichier est ignoré sans avertissement.
- **Correctif** : ne jamais avoir à la fois `group_vars/<groupe>.yml` et `group_vars/<groupe>/`. Le fichier est déplacé dans `group_vars/local/vars.yml`. Vérifier : `ansible-inventory -i inventory/hosts --host localhost | grep docker_host`.
- **Piège associé** : le Docker du runner n'est pas celui du shell. `/var/run/docker.sock` pointe vers Docker Desktop ; le moteur réellement utilisé est Colima (`~/.colima/default/docker.sock`).
- **Origine** : runs 37344489288 et 37355920205 ; correctif `e8fc854`. Un premier correctif (`docker_host` passé à `docker_login`) ne servait à rien tant que la variable n'était pas définie.

## KB-003 · Port d'intégration 8080 déjà pris

- **Date** : 2026-10-05 · **Composant** : tier Web (Caddy)
- **Symptôme** : risque d'échec du démarrage de Caddy, ou contrôle de santé qui répond avec le service d'un autre.
- **Cause** : cAdvisor (conteneur Docker) et un tunnel SSH écoutent sur 8080 sur le Mac Mini.
- **Correctif** : l'intégration passe sur 8070 (production inchangée, 9080). Avant d'attribuer un port : `lsof -nP -iTCP:<port> -sTCP:LISTEN` et `docker ps --format '{{.Names}}\t{{.Ports}}'`.
- **Origine** : décision 8 de [decisions.md](decisions.md) ; commit `85d2dc6`.

## KB-004 · Runs GitHub bloqués en `queued`

- **Date** : 2026-10-05 · **Composant** : runner
- **Symptôme** : les runs restent `queued` pendant des heures.
- **Cause** : aucun runner enregistré sur le dépôt (`gh api repos/logo-solutions/factice/actions/runners` renvoie 0). Les jobs demandent `runs-on: self-hosted`.
- **Correctif** : installer le runner (`~/actions-runner-factice`, service launchd). À la reprise, il traite d'abord les runs les plus anciens : annuler ceux qui sont périmés (`gh run cancel <id>`) pour ne pas déployer d'anciennes versions.
- **Sécurité** : le dépôt est public. Règle « approbation requise pour tous les contributeurs externes » activée (`fork-pr-contributor-approval`), pour qu'un fork ne puisse pas exécuter de code sur le Mac Mini sans accord.

## KB-005 · deploy_stack : « network factice-network declared as external, but could not be found »

- **Date** : 2026-10-05 · **Composant** : Ansible, rôle `deploy_stack`
- **Symptôme** : `Start Docker Compose stack` échoue avec `network factice-network declared as external, but could not be found`, juste après une tâche `Create Docker network` qui affiche `Connection refused` puis `...ignoring`.
- **Cause** : `docker_network` n'avait pas `docker_host`, donc visait le Docker Desktop arrêté ; l'échec était masqué par `ignore_errors: true`. Le réseau n'a jamais été créé dans Colima.
- **Correctif** : `docker_host` sur `docker_network`, `DOCKER_HOST` sur les tâches `shell` Docker, `ignore_errors` retiré (la tâche est idempotente). Règle : tout module ou commande Docker d'un rôle reçoit `docker_host`. Vérifier : `DOCKER_HOST=unix://$HOME/.colima/default/docker.sock docker network ls | grep factice`.
- **Origine** : run 37356475601 ; même famille que KB-002.
- **ITSM** : INC-2026-0001 (ouvert à la main pour ce run ; les suivants le sont par le pipeline).

## KB-006 · Ansible : « Unsupported parameters for (ansible.legacy.uri) module: connect_timeout »

- **Date** : 2026-10-05 · **Composant** : Ansible, rôles `deploy_stack` et `factice`
- **Symptôme** : la tâche `Check healthcheck endpoints` échoue sur les 30 tentatives avec `Unsupported parameters for (ansible.legacy.uri) module: connect_timeout`, alors que le conteneur a démarré.
- **Cause** : le module `uri` d'Ansible n'a pas de paramètre `connect_timeout` (c'est `timeout`). Le paramètre existe pour d'autres modules, d'où l'erreur de copie.
- **Correctif** : `timeout:` à la place, dans `roles/deploy_stack/tasks/main.yml` et `roles/factice/tasks/validation.yml`. Vérifier : `ansible-doc -t module uri | grep -n timeout`.
- **Origine** : run 37357463837 ; correctif de ce commit.
- **ITSM** : INC-2026-0002 (ouvert automatiquement par le pipeline).

## KB-007 · Tier BDD jamais exécuté : app déployée avant la base, PostgreSQL absent, schéma manquant

- **Date** : 2026-10-05 · **Composant** : Ansible, rôle `factice` (tiers BDD et validation)
- **Symptôme** : `Check healthcheck endpoints` échoue 30 fois ; `/health` répond `connect ECONNREFUSED 192.168.5.2:5432`. Le déploiement s'affichait pourtant « completed successfully » malgré une validation en erreur.
- **Cause** : plusieurs défauts du rôle, jamais exécuté avant le pipeline et masqué par des `ignore_errors` et un `rescue` : (1) le tier App était déployé avant le tier BDD ; (2) le rôle installait `postgresql@16` alors que `@18` est présent, avec un `initdb` dans un répertoire que `brew services` n'utilise pas ; (3) `postgresql_query` exige `psycopg2`, absent d'Ansible ; (4) la table `items` n'était créée nulle part ; (5) la production visait le port 5433, pris par un tunnel SSH ; (6) `{{ .Names }}` du format Docker était interprété par Jinja.
- **Correctif** : BDD déployée avant l'app ; cluster Homebrew `postgresql@18` (variable `tier_db_formula`) démarré s'il est absent ; rôle, base et table `items` créés par `psql`, idempotents ; plus d'`ignore_errors` ; la validation échoue réellement. Intégration et production partagent le cluster (port 5432, localhost seulement, atteint depuis Colima par `host.docker.internal`), isolées par base et rôle. Vérifier : `curl localhost:8070/health` puis `POST /items`.
- **Limite connue** : le `pg_hba.conf` par défaut de Homebrew est en `trust` sur localhost, donc le mot de passe n'est pas exigé pour un processus local.
- **Origine** : run 37357901616 ; même famille que KB-005 et KB-006 (erreurs masquées).
- **ITSM** : INC-2026-0003 (ouvert automatiquement par le pipeline).

## KB-008 · Production : « Production deployment cancelled » et environnement GitHub sans relecteur

- **Date** : 2026-10-06 · **Composant** : pipeline, playbook `deploy-factice-production.yml`
- **Symptôme** : `deploy-production` échoue (`Production deployment cancelled`) juste après un `change-gate` réussi ; le job n'a attendu aucune approbation.
- **Cause** : (1) le playbook demandait « yes » au clavier (`pause`), impossible dans un job CI ; (2) l'environnement GitHub `production` n'avait aucun relecteur requis, donc la seconde barrière du flux 2 n'existait pas.
- **Correctif** : le `pause` est remplacé par une exigence d'un `change_id` (`-e change_id=CHG-AAAA-NNNN`, transmis par `ci.yml` depuis le job `change-gate`) ; relecteur requis configuré sur l'environnement `production` (`gh api -X PUT repos/<org>/factice/environments/production`). La confirmation humaine passe par l'approbation ITSM puis par celle de l'environnement. `prevent_self_review` reste faux : un seul humain déclenche et approuve. Vérifier : `gh api repos/<org>/factice/environments/production --jq '.protection_rules'`.
- **Origine** : run 37414908865.
- **ITSM** : INC-2026-0004 (ouvert automatiquement par le pipeline).

## KB-009 · Ansible : « Conditionals must have a boolean result » (assertion sur regex_search)

- **Date** : 2026-10-06 · **Composant** : playbook `deploy-factice-production.yml`
- **Symptôme** : `deploy-production` échoue dès la première tâche avec `Conditional result (True) was derived from value of type 'str'`.
- **Cause** : l'assertion du KB-008 utilisait `change_id | regex_search(...)`, qui renvoie une chaîne et non un booléen ; le correctif n'avait été vérifié qu'en syntaxe, pas exécuté.
- **Correctif** : `change_id is match('^CHG-[0-9]{4}-[0-9]{4}$')`. Règle : tout test d'assertion se valide en exécutant un cas valide et un cas invalide (`ansible-playbook` sur un playbook minimal), pas seulement `--syntax-check`.
- **Origine** : run 37416691251 ; suite de KB-008. Chaque tentative ratée consomme un changement ITSM (CHG-2026-0014 clos en échec).
- **ITSM** : INC-2026-0005 (ouvert automatiquement par le pipeline).

## KB-010 · Production : « Bind for 0.0.0.0:3001 failed » — port pris par l'intégration ou un autre processus

- **Date** : 2026-10-06 · **Composant** : Docker, rôle `factice` (tier App, production)
- **Symptôme** : le déploiement production échoue à la création du conteneur `factice-app` : `driver failed programming external connectivity on endpoint factice-app: Bind for 0.0.0.0:3001 failed`.
- **Cause** : le port 3001 est déjà pris, vraisemblablement par le conteneur `factice-app` d'intégration (port 3000 en intégration, 3001 en production, même machine Colima). L'isolation par port n'est pas suffisante quand deux environnements tournent sur le même hôte.
- **Correctif** : avant de déployer en production, arrêter les conteneurs d'intégration (`docker stop factice-app` ou `docker-compose -f /Users/logo/factice/integration/app/docker-compose.yml down`). Règle : deux environnements sur le même Mac Mini doivent avoir des ports distincts (fait) ET une séquence de déploiement qui évite les conflits (à améliorer : actuellement, l'intégration et la production tournent simultanément). Alternative : Ansible met en `pause` pour que l'opérateur arrête l'environnement précédent avant.
- **Limite** : factice n'isole pas les environnements (pas de VMs, pas de namespaces). Sur une vraie infrastructure, la production est sur une machine différente.
- **Origine** : run 37417815665.
- **ITSM** : INC-2026-0006 (ouvert automatiquement par le pipeline).

## KB-011 · Build job échoue silencieusement : docker login impossible sur le port 5001

- **Date** : 2026-10-06 · **Composant** : GitHub Actions, build job, registre Nexus
- **Symptôme** : la commande `docker_login "$NEXUS_DOCKER_CANDIDAT"` du script `publish-candidate.sh` échoue silencieusement après l'étape « SBOM CycloneDX », sans message d'erreur visible. Le job s'arrête avec « Process completed with exit code 1 ».
- **Cause** : le port 5001 attendu (configuré dans le workflow) est occupé par le multiplexeur SSH de Colima (VM daemon). `lsof -nP -iTCP:5001` révèle un processus `ssh` (PID 87414, Lima hostagent). Le registre Nexus écoute bien sur 5001-5004 (dans le docker-compose), mais ils sont masqués.
- **Correctif** : le port Docker de Nexus est 8082 (connecteur HTTP dédié au repo Docker hosted, dockerfile ligne 12). Changer `NEXUS_DOCKER_CANDIDAT=localhost:5001` en `localhost:8082` dans `.github/workflows/ci.yml` ligne 145. Attente : `docker login localhost:8082` doit fonctionner. Vérifier : `curl http://localhost:8082/v2/` → 401 (attendu, auth requise).
- **Origine** : run 37512397300 (build ❌, logs montrent exit 1 sans contexte). Découverte : `lsof` et `docker ps` sur le Mac Mini.
- **À vérifier** : après ce fix, relancer le workflow et vérifier que le build job passe.

Note technique : les ports 5001-5004 dans le docker-compose de Nexus existent, mais le tunnel SSH de Colima les capture. C'est une collision de ressource : deux services veulent le même port. Solution long terme : reconfigurer Colima pour libérer 5001-5004, ou assigner un autre range au tunnel SSH.
