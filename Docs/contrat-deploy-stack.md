# Contrat d'appel de `roles/deploy_stack`

## Objectif

`deploy_stack` est un rôle Ansible générique qui factorise le squelette de déploiement Docker répété dans chaque service NAS-LOGO (Immich, Paperless, etc.). Il gère :
- Créer le répertoire d'installation
- Templater `.env` (variables sensibles)
- Templater `docker-compose.yml`
- Lancer `docker-compose pull && docker-compose up -d`
- Healthcheck en retry jusqu'à 200 OK
- Restart idempotent via handler

Le rôle appelant fournit les templates et les variables ; `deploy_stack` fait le reste.

## Variables attendues

Toutes les variables doivent être préfixées `deploy_*` pour éviter toute collision.

### Obligatoires

| Variable | Type | Description |
|---|---|---|
| `deploy_install_dir` | string | Répertoire cible sur l'hôte (ex: `~/immich`, `/opt/nexus`) |
| `deploy_compose_template` | string | Chemin vers le template `docker-compose.yml.j2` fourni par l'appelant (relatif à `roles/<role>/templates/`) |

### Optionnels

| Variable | Type | Défaut | Description |
|---|---|---|---|
| `deploy_env_template` | string | null | Chemin vers le template `.env.j2` si le service a besoin de variables d'environnement |
| `deploy_healthcheck_url` | string | null | URL à pinger après déploiement (ex: `http://localhost:3001/health`). Si absent, pas de healthcheck (juste attendre que `docker-compose up` réussisse) |
| `deploy_healthcheck_retries` | int | 30 | Nombre de tentatives de healthcheck |
| `deploy_healthcheck_delay` | int | 10 | Délai en secondes entre chaque retry |
| `deploy_pull_policy` | string | `always` | Policy pour `docker-compose` (`always`, `missing`, `never`) |

### Variables globales (déjà existantes dans NAS-LOGO)

`deploy_stack` utilise ces variables globales (définies dans `inventory/group_vars/all/vars.yml`), pas besoin de les fournir :

| Variable | Rôle |
|---|---|
| `docker_host` | Chemin vers le socket Docker (ex: `unix:///Users/logo/.colima/default/docker.sock`) |
| `docker_bin` | Commande Docker à utiliser (ex: `docker`, `colima nerdctl`) |

## Exemple d'appel

```yaml
# roles/my-service/tasks/main.yml

- name: Deploy my-service via deploy_stack
  include_role:
    name: deploy_stack
  vars:
    deploy_install_dir: "{{ ansible_env.HOME }}/my-service"
    deploy_compose_template: docker-compose.yml.j2
    deploy_env_template: .env.j2
    deploy_healthcheck_url: "http://localhost:8080/health"
    deploy_healthcheck_retries: 30
    deploy_healthcheck_delay: 10
```

## Ce que fait `deploy_stack`

### 1. Créer le répertoire

```yaml
- name: Create install directory
  file:
    path: "{{ deploy_install_dir }}"
    state: directory
    mode: "0750"
```

### 2. Templater `.env` (optionnel)

```yaml
- name: Deploy .env
  template:
    src: "{{ deploy_env_template }}"
    dest: "{{ deploy_install_dir }}/.env"
    mode: "0600"
  no_log: true
  when: deploy_env_template is defined
  notify: restart <service>
```

### 3. Templater `docker-compose.yml`

```yaml
- name: Deploy docker-compose.yml
  template:
    src: "{{ deploy_compose_template }}"
    dest: "{{ deploy_install_dir }}/docker-compose.yml"
    mode: "0640"
  notify: restart <service>
```

### 4. Pull + start

```yaml
- name: Start service
  community.docker.docker_compose_v2:
    project_src: "{{ deploy_install_dir }}"
    state: present
    pull: "{{ deploy_pull_policy }}"
    docker_cli: "{{ docker_bin }}"
  environment:
    DOCKER_HOST: "{{ docker_host }}"
```

### 5. Healthcheck (optionnel)

```yaml
- name: Wait for service health
  uri:
    url: "{{ deploy_healthcheck_url }}"
    status_code: 200
    timeout: 10
  retries: "{{ deploy_healthcheck_retries }}"
  delay: "{{ deploy_healthcheck_delay }}"
  when: deploy_healthcheck_url is defined
```

### 6. Handler restart (idempotent)

```yaml
# roles/deploy_stack/handlers/main.yml
- name: restart <service>
  community.docker.docker_compose_v2:
    project_src: "{{ deploy_install_dir }}"
    state: present
    recreate: always
    docker_cli: "{{ docker_bin }}"
  environment:
    DOCKER_HOST: "{{ docker_host }}"
```

## Secrets et variables sensibles

### Où les mettre

Secrets (mots de passe, API keys, credentials) doivent être fournis par le rôle appelant via le template `.env.j2` :

```jinja2
{# roles/my-service/templates/.env.j2 #}
DB_PASSWORD={{ db_password }}
API_KEY={{ api_key }}
```

Les variables `db_password`, `api_key` sont définies soit :
- Dans `inventory/group_vars/all/vars.yml` (non-secret)
- Dans `inventory/group_vars/all/vault.yml` (chiffré Ansible Vault)
- Directement dans le rôle appelant via `vars`

### Exemple avec vault

```yaml
# inventory/group_vars/all/vault.yml
---
# ansible-vault edit <file>
vault_my_service_db_password: "secret-password"
vault_my_service_api_key: "secret-key"

# roles/my-service/defaults/main.yml
my_service_db_password: "{{ vault_my_service_db_password }}"
my_service_api_key: "{{ vault_my_service_api_key }}"
```

## Idempotence

`deploy_stack` est **fully idempotent** :
- Second run = aucun changement (sauf si `docker-compose.yml` change, auquel cas handler redémarre)
- Safe à re-lancer sans risque

Test :
```bash
ansible-playbook -i inventory/hosts site.yml --tags my-service
# Puis :
ansible-playbook -i inventory/hosts site.yml --tags my-service
# Second run : changed=0 (sauf if files changed)
```

## Limitations et out-of-scope

`deploy_stack` gère **uniquement** les conteneurs Docker. Hors scope :
- Installation de dépendances système (Homebrew, apt, etc.)
- Création de bases de données (utiliser `community.postgresql`, etc.)
- Configuration de processes natifs (LaunchAgent, systemd, etc.)
- Post-deployment logic métier (créer des comptes, seed, etc.)

Pour tout cela, le rôle appelant (ex: `roles/my-service`) reste responsable.

## Exemple d'utilisation dans factice

```yaml
# roles/factice/tasks/tier_app.yml

- name: Deploy application tier via deploy_stack
  include_role:
    name: deploy_stack
  vars:
    deploy_install_dir: "{{ factice_app_dir }}"
    deploy_compose_template: docker-compose.app.yml.j2
    deploy_env_template: .env.app.j2
    deploy_healthcheck_url: "http://localhost:3001/health"
    deploy_healthcheck_retries: 30
    deploy_healthcheck_delay: 10
```

The role `deploy_stack` handles the container lifecycle. Post-deployment logic (database initialization, seed data, etc.) remains in the calling role.
