# Architecture — Les 3 tiers de factice

## Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│ Client (navigateur, API)                                         │
└─────────────────────────────────────────────────────────────────┘
                            ↓ HTTP(S)
┌─────────────────────────────────────────────────────────────────┐
│ TIER WEB — Reverse proxy natif (NON conteneurisé)               │
│                                                                   │
│ Process macOS : Caddy or nginx (installed via Homebrew)         │
│ Gestion : LaunchAgent (com.factice.web.plist)                   │
│ Config : template Ansible (Caddyfile.j2 or nginx.conf.j2)       │
│ Écoute : http://localhost:8080 (port de service)                │
│                                                                   │
│ Rôle : routing HTTP, reverse proxy vers le tier App             │
│ Redémarrage : manuel (launchctl) + brew services                │
└─────────────────────────────────────────────────────────────────┘
                            ↓ HTTP local
┌─────────────────────────────────────────────────────────────────┐
│ TIER APP — Conteneur Docker (NON natif)                         │
│                                                                   │
│ Image : Node.js/Express (construit dans CI, pushé vers Nexus)   │
│ Déploiement : docker-compose (tiré depuis Nexus:8082)           │
│ Gestion : roles/factice (include_role: deploy_stack)            │
│ Écoute : http://localhost:3001 (port interne au réseau Docker)  │
│                                                                   │
│ Rôle : API applicatif                                            │
│  - GET  /health          → 200 OK (healthcheck Ansible)         │
│  - GET  /items           → liste items (lit PostgreSQL)          │
│  - POST /items?name=X    → créé un item (écrit PostgreSQL)       │
│ Redémarrage : docker-compose up -d (idempotent via deploy_stack)│
└─────────────────────────────────────────────────────────────────┘
                            ↓ TCP:5432 (local)
┌─────────────────────────────────────────────────────────────────┐
│ TIER BDD — PostgreSQL natif (NON conteneurisé)                  │
│                                                                   │
│ Process macOS : PostgreSQL (installé via Homebrew)              │
│ Gestion : brew services (com.homebrew.postgresql)               │
│ Config : user/password via Ansible (dans vault)                 │
│ Écoute : localhost:5432                                          │
│                                                                   │
│ Rôle : persistance des données                                   │
│  - DB : factice_db (créée idempotente par Ansible)              │
│  - User : factice_user (password dans vault)                    │
│  - Schema : une table items (name TEXT, created_at TIMESTAMP)   │
│ Redémarrage : brew services restart postgresql                  │
└─────────────────────────────────────────────────────────────────┘
```

## Flux de requête

```
Client
  → GET http://localhost:8080/items
    ↓
TIER WEB (Caddy/nginx)
  - Reçoit sur :8080
  - Reverse proxy → http://localhost:3001/items
    ↓
TIER APP (conteneur Docker)
  - Reçoit sur :3001
  - Query : SELECT * FROM items WHERE ... 
    ↓
TIER BDD (PostgreSQL)
  - Reçoit requête TCP:5432 du conteneur App
  - Exécute SELECT, retourne résultat
    ↓
TIER APP
  - Formate réponse JSON
  - Envoie au tier Web
    ↓
TIER WEB
  - Reçoit réponse du tier App
  - Envoie au client
    ↓
Client
  ← 200 OK + JSON array
```

## Pattern Ansible par tier

### Tier App (conteneur Docker) — `deploy_stack`

```yaml
# roles/factice/tasks/tier_app.yml
- name: Deploy tier App via deploy_stack
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

**Responsibilities of `deploy_stack`:**
- Créer `{{ factice_app_dir }}`
- Templater `.env.app.j2` (variables Nexus, credentials DB)
- Templater `docker-compose.app.yml.j2`
- `docker-compose pull always`
- `docker-compose up -d`
- Pinger healthcheck jusqu'à 200 OK

### Tier Web (reverse proxy natif) — pattern LaunchAgent

```yaml
# roles/factice/tasks/tier_web.yml
- name: Install Caddy via Homebrew
  community.general.homebrew:
    name: caddy
    state: present

- name: Deploy Caddyfile
  template:
    src: Caddyfile.j2
    dest: /usr/local/etc/caddy/Caddyfile
  notify: restart factice web

- name: Install LaunchAgent
  template:
    src: com.factice.web.plist.j2
    dest: "{{ ansible_env.HOME }}/Library/LaunchAgents/com.factice.web.plist"
  notify: load factice web

- name: Start service
  shell: launchctl start com.nas-logo.factice-web
```

**Pattern** : identique à celui utilisé pour Tailscale dans `roles/securite`

### Tier BDD (PostgreSQL natif) — brew services

```yaml
# roles/factice/tasks/tier_db.yml
- name: Install PostgreSQL via Homebrew
  community.general.homebrew:
    name: postgresql
    state: present

- name: Start PostgreSQL via brew services
  shell: brew services start postgresql

- name: Create database and user
  community.postgresql.postgresql_db:
    name: factice_db
    state: present
  become: yes
  become_user: postgres

- name: Create application user
  community.postgresql.postgresql_user:
    name: factice_user
    password: "{{ factice_db_password }}"
    db: factice_db
    priv: "ALL"
  become: yes
  become_user: postgres
```

## Ressources et ports

| Tier | Process | Port | Réseau | Qui accède |
|---|---|---|---|---|
| Web | Caddy/nginx | 8080 | Localhost + Tailscale | Client, tests |
| App | Node.js (Docker) | 3001 | Docker bridge + localhost | Tier Web, healthcheck |
| BDD | PostgreSQL | 5432 | Localhost seulement | Tier App, Ansible (init DB) |

## Redémarrage robuste

Après restart du Mac Mini, Ansible garantit que les 3 tiers redémarrent :

1. **Tier Web** : LaunchAgent relancé au boot macOS
2. **Tier App** : `docker-compose up -d` (restart policy: unless-stopped)
3. **Tier BDD** : `brew services` relancé au boot

Validation : `curl http://localhost:8080/health` → 200 OK (implique tous les 3 tiers up)

## Idempotence

Chaque tier est idempotent (safe to re-run) :
- **Web** : template identique, redémarrage seulement si changé
- **App** : `deploy_stack` = pull + restart seulement si image change
- **BDD** : Ansible `postgresql_db`/`postgresql_user` = créer si absent (pas de changement si existe)

Test : `ansible-playbook -i inventory/hosts deploy.yml` × 2 → deuxième run = `changed=0`
