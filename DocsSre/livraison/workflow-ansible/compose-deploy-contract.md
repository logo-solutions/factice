# Contrat d'appel de `roles/compose_deploy`

## Objectif

`compose_deploy` est le rôle Ansible générique commun à l'écosystème : le même squelette déploie maisonnettev2 (Hetzner), Nexus et factice (Mac mini). Il remplace depuis le 2026-10-09 l'ancien rôle propre à factice, `deploy_stack` (fiche [KB-014](../../kb.md)).

Source de référence : `maisonnettev2/ansible/roles/compose_deploy`, testée par Molecule (destruction → convergence → idempotence → vérification). Factice et Nexus en gardent une copie, à resynchroniser à chaque évolution.

Le rôle :

1. synchronise le code à partir d'une archive (`compose_deploy_archive`) — ou, sans archive, utilise le compose **en place**, comme factice ;
2. écrit le `.env` à partir des secrets (si `compose_deploy_manage_env`) ;
3. se connecte au registre, tire les images listées, se déconnecte ;
4. lance `docker compose up -d --remove-orphans` ;
5. supprime les images sans tag (désactivable) ;
6. exécute les commandes post-démarrage (migrations…) ;
7. vérifie : conteneurs attendus en marche, puis contrôles HTTP.

Il n'utilise que `ansible.builtin` et la CLI `docker` : aucun SDK Python Docker n'est requis.

## Variables

Déclarées et validées par `meta/argument_specs.yml`.

| Variable | Défaut | Description |
|---|---|---|
| `compose_deploy_dir` | (obligatoire) | dossier de la pile (compose et `.env`) |
| `compose_deploy_compose_file` | `docker-compose.yml` | fichier compose, relatif au dossier |
| `compose_deploy_archive` | `""` | archive du code ; vide = compose utilisé en place, sans synchronisation |
| `compose_deploy_project_name` | `""` | nom du projet compose (`-p`) |
| `compose_deploy_env_file` | `.env` | passé à `--env-file` ; vide = aucun |
| `compose_deploy_manage_env` | `false` | écrit le `.env` à partir de `compose_deploy_secrets` |
| `compose_deploy_registry` / `_user` / `_token` | `ghcr.io` / `""` / `""` | connexion au registre ; sans jeton, pas de connexion |
| `compose_deploy_pull_services` | `[]` | services dont l'image est tirée avant le démarrage |
| `compose_deploy_prune_images` | `true` | supprime les images sans tag ; `false` sur un hôte partagé |
| `compose_deploy_post_up_commands` | `[]` | commandes `docker compose exec -T` après le démarrage |
| `compose_deploy_required_containers` | `[]` | conteneurs qui doivent être en marche |
| `compose_deploy_health_checks` | `[]` | liste `{url, status}` |
| `compose_deploy_health_retries` / `_delay` | `30` / `5` | tentatives et pause des contrôles |

## Appel par factice

Extrait de `roles/factice/tasks/tier_app.yml` : le rôle `factice` rend `docker-compose.yml` et `.env`, crée le réseau `factice-network`, puis :

```yaml
- name: Déployer le conteneur applicatif (compose_deploy)
  ansible.builtin.include_role:
    name: compose_deploy
    apply:
      environment:
        DOCKER_HOST: "{{ docker_host | default('unix:///var/run/docker.sock') }}"
  vars:
    compose_deploy_dir: "{{ tier_app_base_dir }}"
    compose_deploy_project_name: "{{ factice_app_name }}-{{ factice_environment }}"
    compose_deploy_registry: "{{ factice_release_image.split('/')[0] if factice_release_image | length > 0 else '' }}"
    compose_deploy_registry_user: "{{ factice_registry_user }}"
    compose_deploy_registry_token: "{{ lookup('ansible.builtin.env', 'NEXUS_DEPLOY_PASSWORD') if factice_release_image | length > 0 else '' }}"
    compose_deploy_pull_services: "{{ ['app'] if factice_release_image | length > 0 else [] }}"
    compose_deploy_prune_images: false
    compose_deploy_required_containers: ["{{ tier_app_container_name }}"]
    compose_deploy_health_checks:
      - {url: "{{ tier_app_healthcheck_endpoint }}", status: 200}
```

Choix propres à factice :

- **Projet compose par environnement** : `factice-integration`, `factice-production` (convention de l'écosystème). Les deux environnements ont un dossier `app` : sans `-p`, ils partageraient le projet `app`, et `--remove-orphans` de l'un supprimerait le conteneur de l'autre (KB-014).
- **Conteneur par environnement** : `factice-app` (integration), `factice-app-production`.
- **Aucune suppression d'image** : le Mac mini héberge d'autres piles (Immich, Nexus).
- **Connexion au registre Nexus** seulement pour une release (`factice_release_image`), avec le compte de lecture `svc-deploiement` ; le rôle se déconnecte après le pull.

## Secrets

Les secrets sont rendus par l'appelant dans `.env` (mode `0600`) à partir du coffre Ansible ; le jeton du registre vient de l'environnement (`NEXUS_DEPLOY_PASSWORD`) et n'est jamais journalisé (`no_log`).

## Idempotence

Un second passage sans changement de configuration ni d'image rend `changed=0` : `up -d` annonce « Running » pour un service inchangé. Seuls un compose modifié ou une nouvelle image recréent le conteneur. L'ancien paramètre `recreate_containers` (recréation forcée en production) n'existe plus : une release a une nouvelle empreinte, donc un nouveau conteneur.

## Hors périmètre

Le rôle ne gère que des piles Docker Compose. Restent au rôle `factice` : PostgreSQL et Caddy natifs, création de la base, LaunchAgent, validation métier.

## Écarts traités par la migration

| Constat sur `deploy_stack` | Avec `compose_deploy` |
|---|---|
| Pas de `meta/argument_specs.yml` | variables déclarées et validées |
| `docker system prune -f` (option `prune_on_deploy`) pouvait supprimer des ressources d'autres piles | seulement `docker image prune` des images sans tag, désactivé pour factice |
| Pas de test du rôle | scénario Molecule (dans maisonnettev2) |
| Même projet compose pour les deux environnements | projet nommé par environnement |
| Modules sans nom qualifié | `ansible.builtin` partout ; `ansible-lint` profil `production` |

## Références

- [bonnes-pratiques-ansible.md](bonnes-pratiques-ansible.md)
- [workflow-ansible.md](workflow-ansible.md)
- [KB-014](../../kb.md)
