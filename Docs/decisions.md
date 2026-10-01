# Décisions d'architecture

## Stack applicatif : Node.js/Express (pas Python)

**Décision** : Backend en Node.js/Express.

**Raison** : Simplicité et popularité.
- Node.js + npm est standard pour CI/CD
- Express est minimal et représentatif
- Docker support de Node.js est mature

**Alternative considérée** : Python (FastAPI)
- Equally valid choice
- Slightly heavier runtime

**Conclusion** : Node.js for simplicity and wide CI/CD support.

---

## Reverse proxy natif (pas Docker)

**Décision** : Caddy or nginx installed via Homebrew, run as native macOS process (LaunchAgent).

**Raison** : Demonstrate Ansible orchestration beyond containers.
- Show how to manage Homebrew + LaunchAgent services via Ansible
- Realistic for production deployments (not everything runs in Docker)
- Validates idempotent, declarative infrastructure patterns

**Alternative considered** : Run reverse proxy as a Docker container
- Simpler (everything via `deploy_stack`)
- Loses the opportunity to document native service orchestration
- Less representative of real-world mixed deployments

**Conclusion** : Native reverse proxy via Homebrew + LaunchAgent.

---

## Database native (PostgreSQL Homebrew, not containerized)

**Décision** : PostgreSQL installed via Homebrew, managed by `brew services`.

**Raison** : Demonstrate multi-tier orchestration.
- Shows Ansible managing services beyond Docker
- Validates user/password management in vault
- Realistic for production deployments with managed databases

**Alternative considered** : SQLite (local file)
- Ultra-simple (zero external dependencies)
- Not representative (no service orchestration, no user management)

**Conclusion** : PostgreSQL via Homebrew + `brew services`.

---

## Nexus provisionné par Ansible (pas lancé manuellement)

**Décision** : `roles/nexus` déploie Nexus via `deploy_stack`, puis provisionne le repo Docker hosted via API REST.

**Raison** : IaC complet.
- Nexus existe (`/Volumes/logousb/SSD/Projects/Nexus/docker-compose.yml`) mais est jamais lancé
- L'Infrastructure As Code, c'est "tout déclaratif, rien de manuel"
- `roles/nexus` = démo "si on veut vraiment Nexus, on le déploie en Ansible, pas à la main"

**Alternative considérée** : Lancer Nexus manuellement avant le plan Ansible
- Plus simple pour le PoC
- Mais perd l'occasion de montrer "Nexus est un service comme les autres"

**Conclusion** : `roles/nexus` déploie Nexus et provisionne le repo automatiquement.

---

## Runner GitHub Actions self-hosted (pas runner cloud)

**Décision** : GitHub Actions runner installé sur le Mac Mini comme LaunchAgent.

**Raison** : Accès réseau à Nexus.
- Nexus tourne sur le Mac Mini, accessible via Tailscale (100.113.214.55:8082)
- Runner cloud GitHub ne peut pas atteindre Nexus sans IP publique/tunnel
- Runner self-hosted = solution "real-world" (l'écosystème logo-solutions n'expose pas de services publiquement)

**Alternative considérée** : Expose Nexus via tunnel Cloudflare
- Puis utilise runner cloud GitHub
- Mais change la posture de sécurité (Nexus serait public)
- Plus compliqué, moins représentatif

**Conclusion** : Runner self-hosted sur le Mac Mini.

---

## CI/CD workflow simple (npm test, docker build, docker push)

**Décision** : Workflow `ci.yml` : npm install → npm test → docker build → docker push Nexus.

**Raison** : Démo du pattern maisonnettev2 (qui utilise `docker/build-push-action`).
- maisonnettev2 : tests → build image → push ghcr.io
- factice : même chose, mais vers Nexus (local) au lieu de ghcr.io (cloud)
- Montre que le pattern "registry Docker dans la CI" est générique

**Alternative considérée** : Skip tests, juste build + push
- Plus rapide à tester localement
- Mais perd l'occasion de montrer "tests, puis push seulement si OK"

**Conclusion** : Tests + build + push (pattern complet).

---

## Port 8080 pour le reverse proxy (pas 80)

**Décision** : Caddy/nginx écoute sur `localhost:8080`.

**Raison** : Éviter les ports privilégiés sur macOS.
- Port 80 = requires sudo, problématique avec Homebrew/LaunchAgent
- Port 8080 = standard, accessible en user-space
- Clients testent sur `localhost:8080/health` ou via tunneling/reverse proxy local

**Alternative considérée** : Port 80
- Réaliste en prod (quand Caddy est le vrai reverse proxy)
- Mais complique le déploiement local (sudo, Homebrew quirks)

**Conclusion** : Port 8080 local (prod use `ansible_port_mapping` variable si besoin).

---

## Pas de SSL/TLS en PoC

**Décision** : Communication HTTP en local (pas HTTPS).

**Raison** : Scope du PoC.
- SSL = hors scope (confirmé dans le plan)
- Local testing = HTTP suffisant
- Prod peut ajouter SSL via Caddy (déjà supporté)

**Conclusion** : HTTP uniquement en dev/test.

---

## Trois tiers séparés (pas monolithe)

**Décision** : Conteneur App, reverse proxy natif, BDD native = 3 processus distincts.

**Raison** : Démo de l'architecture "réelle".
- Monolithe = plus simple mais perd la démo d'orchestration multi-tier
- factice = démo du pattern "Ansible orchestre plusieurs types de services"
- 3 tiers = montre réseau (conteneur → BDD), redémarrage (3 services), healthcheck (tous les 3 doivent être up)

**Conclusion** : Trois tiers séparés.

---

## Pas de clustering, pas de load-balancing

**Décision** : Un seul Mac Mini, une seule instance de chaque tier.

**Raison** : Scope et complexité.
- Clustering = hors scope
- Démo de "single-machine orchestration" = suffisant

**Conclusion** : Instance unique par tier.

---

## Mémoriser dans le projet, pas dans NAS-LOGO

**Décision** : Documentation vit dans `factice/Docs/`, pas dans NAS-LOGO.

**Raison** : Séparation des concerns.
- factice = un repo indépendant (pattern écosystème)
- Documentation = liée au projet factice
- NAS-LOGO = garde ses propres rôles, métier, doc

**Conclusion** : Documentation et code applicatif dans factice/ uniquement.

---

## Mémoire projet vs Mémoire Claude Code

**Décision** : Mémoriser ce document entier dans la mémoire Claude Code (pas dans git).

**Raison** : Les décisions ne changent pas souvent, mais sont utiles pour les futurs contributeurs.

**Conclusion** : `maisonnettev2_factice_decisions.md` dans la mémoire Claude Code.
