# Isolation et réseau

## Zones de sécurité

Factice définit trois zones distinctes :

### Zone 1 : Internet (public)

- **Composants** : GitHub, Nexus (externe)
- **Authentification** : HTTPS + token / clé API
- **Flux autorisés** :
  - CI/CD → Nexus (push candidat après build)
  - Webhooks Nexus → Ansible (trigger déploiement)

### Zone 2 : VPN Tailscale (semi-trusted)

- **Composants** : Développeurs, administrateurs
- **Authentification** : Tailscale SSO
- **Flux autorisés** :
  - Curl http://100.113.214.55:8080/ (intégration)
  - Curl http://100.113.214.55:9080/ (production)
  - SSH vers hôte (Ansible)

### Zone 3 : Hôte local (trusted)

- **Composants** : Tier Web (Caddy), Tier App (Node.js), Tier BDD (PostgreSQL)
- **Authentification** : localhost / docker-network
- **Flux autorisés** :
  - Caddy ↔ App (reverse proxy)
  - App ↔ PostgreSQL (TCP localhost)
  - Caddy /health → App /health (healthcheck)

## Segmentation réseau

### Ports exposés

| Tier | Port | Environnement | Accès |
|---|---|---|---|
| Caddy | 8080 | Intégration | Localhost, VPN, CI/CD healthcheck |
| Caddy | 9080 | Production | Localhost, VPN, CI/CD healthcheck |
| PostgreSQL | 5432 | Intégration | Localhost, Docker network (App) |
| PostgreSQL | 5433 | Production | Localhost, Docker network (App) |
| Node.js /metrics | 3000/3001 | Tous | Localhost (Prometheus scrape) |

### Ports NON exposés

- SSH (déploiement par Ansible, pas de SSH direct vers conteneurs)
- Admin Caddy (interface admin désactivée)
- Replication PostgreSQL (aucune réplication)

## Firewall local

Activer UFW sur l'hôte (Mac Mini) :

```bash
# Autoriser SSH (Ansible)
sudo ufw allow from 100.113.214.0/24 to any port 22 proto tcp

# Autoriser HTTP (Caddy integ + prod)
sudo ufw allow from 100.113.214.0/24 to any port 8080 proto tcp
sudo ufw allow from 100.113.214.0/24 to any port 9080 proto tcp

# Refuser tout le reste
sudo ufw default deny incoming
sudo ufw enable
```

## Réseau Docker

Créer un réseau dédié pour chaque environnement (déjà géré par `roles/deploy_stack`) :

```bash
docker network create --driver bridge factice-integration
docker network create --driver bridge factice-production
```

- Aucun conteneur n'expose ses ports directement
- Seul Caddy (natif) expose 8080/9080
- App et PostgreSQL sont joins au réseau interne uniquement

## TLS/HTTPS

### Intégration (localhost)

- HTTP plain (8080)
- Certificat self-signed ou local (Mkcert)

### Production (distant)

- HTTPS (443 → 9080)
- Certificat valide (Let's Encrypt via Caddy)
- Redirect 80 → 443

Configuration Caddyfile :

```caddyfile
factice.example.com {
  encode gzip
  reverse_proxy localhost:9080 {
    header_up X-Forwarded-For {http.request.remote.host}
  }
}
```

## Principes de least privilege

| Rôle | Ressource | Permission | Justification |
|---|---|---|---|
| CI/CD (GitHub Actions) | Nexus | Push candidat uniquement | Immutabilité release |
| Ansible runner | Nexus | Lecture + pull images | Déploiement par digest |
| PostgreSQL user (app) | Base `factice_*` | SELECT, INSERT, UPDATE | Pas DROP, pas DDL |
| Caddy process | Filesystem | /etc/caddy/Caddyfile RO, /var/log/caddy RW | Config immuable en prod |
| Node.js process | Filesystem | /app RO, /tmp RW | Code immuable, logs temporaires |

## Prochaines étapes

1. Configurer UFW sur hôte avec règles de base
2. Lancer healthchecks post-déploiement en VPN (probe depuis CI)
3. Tester isolation réseau (empêcher accès croisé integ ↔ prod)
4. Documenter procédure d'escalade en cas de breach réseau
