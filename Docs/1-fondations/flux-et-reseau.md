# Flux et réseau

## Architecture générale

L'infrastructure de factice s'appuie sur trois domaines :

1. **CI/CD (GitHub)** : tests, build, publication vers le registry
2. **Registry (Nexus)** : stockage immuable, promotion dev → production
3. **Orchestration Ansible** : déploiement sur l'hôte

## Flux général

```
[Git commit] 
    ↓ (webhook)
[GitHub Actions CI/CD]
    ├→ Build + tests
    ├→ Publie image dans Nexus (candidat)
    └→ Demande d'approbation
           ↓
[Approbation manuelle (GitHub)]
    ├→ Promotion Nexus (candidat → release)
    └→ Webhook → Ansible
           ↓
[Ansible playbook]
    ├→ Lecture du registre (Vault pour crédentials)
    ├→ Déploiement des trois tiers
    ├→ Santé post-déploiement
    └→ Réconciliation (événement optionnel vers CMDB)
```

## Zones de sécurité

| Zone | Composants | Réseau | Accès |
|---|---|---|---|
| **CI/CD** | GitHub Actions | Internet | Public (branche main + PRs authentifiées) |
| **Registry** | Nexus | VPN Tailscale | Lecture : tous les services ; Écriture : CI/CD seul |
| **Hôte** | Mac Mini, Caddy, App, PostgreSQL | Local | SSH (Ansible) + curl (healthcheck) |

## Flux par environnement

### Intégration (:8080, :5432 BDD)

- Les deux tiers (Web, App, BDD) tournent en mode rapide
- Images Docker tirées depuis Nexus avec politiques `always`
- PostgreSQL sur localhost, accessible en local uniquement
- Idempotence : redéploiement sans casse

### Production (:9080, :5433 BDD)

- Les trois tiers tournent en mode « production »
- Images Docker tirées par empreinte (digest) depuis Nexus
- PostgreSQL sauvegardé régulièrement
- Gates : approbation GitHub avant chaque promotion

## Accès aux services

| Service | Port | Accès | Via |
|---|---|---|---|
| Caddy (integ) | 8080 | Local + VPN | HTTP |
| Caddy (prod) | 9080 | Local + VPN | HTTP |
| PostgreSQL (integ) | 5432 | Conteneur + localhost | TCP |
| PostgreSQL (prod) | 5433 | Conteneur + localhost | TCP |
| Nexus | Internet | CI/CD + Ansible (crédentials Vault) | HTTPS |
| GitHub Actions | Internet | Public | HTTPS |

## Sécurité au niveau réseau

- Les crédentials Nexus résident dans le coffre Ansible (`vault.yml`)
- Pas d'exposition directe de PostgreSQL au réseau externe
- Webhooks Nexus → Ansible authentifiés par token (à configurer)
- Caddy sur ports 8080/9080 (pas de port 80 en prod)
