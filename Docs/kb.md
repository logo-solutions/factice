# Base de connaissances

Une fiche par problème rencontré : symptôme, cause, correctif, et le commit ou le run où il est apparu. À ajouter à la fin, jamais réécrite (une fiche fausse est corrigée par une nouvelle fiche qui la remplace). Les fiches sont lisibles sur github.com, chacune avec un lien permanent par ancre.

Format : `KB-NNN`, titre, date, composant.

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
