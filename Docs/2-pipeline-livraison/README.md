# 2. Socle : pipeline de livraison

## Objectif

Comprendre la **chaîne indissociable** : CI/CD → Registry → Workflows Ansible.

C'est le cœur du système de livraison continu et immuable.

## Structure

### [ci-cd/](ci-cd/) — Build et promotion
- Pipeline CI/CD : tests, construction, publication en candidat, contrôles, promotion en release
- Comptes de service cloisonnés (build, promotion, déploiement)
- Dépendances entre étapes

### [registry/](registry/) — Nexus et gouvernance
- Dépôts (candidat, release, proxy, groupe)
- Immuabilité des releases
- SBOM et métadonnées
- Promotion par republication

### [orchestration/](orchestration/) — Ansible et déploiement
- Orchestration des trois tiers (BDD, App, Web)
- Rôle générique `deploy_stack`
- Contrôles de santé, idempotence
- Déploiement par empreinte (digest)

## Points clés

| Concept | Rôle |
|---|---|
| **Empreinte (digest)** | Lien immuable entre Registry et Ansible |
| **Promotion** | Contrôles → republication → immuabilité |
| **Cloisonnement** | Chaque compte n'a que les droits nécessaires |
| **Idempotence** | Relancer un déploiement = pas de changement |

## Flux complet

```
Développeur pousse du code
    ↓
CI/CD build (tests, docker build)
    ↓
Publication en candidat (docker-candidat:5001)
    ↓
Promotion : contrôles → republication en release (docker-release:5002)
    ↓
Ansible tire l'image par empreinte
    ↓
Déploiement sur hôte (intégration automatique, production manuel)
    ↓
Healthcheck, événement de déploiement
```

## Pour qui ?

- **DevOps** (tout le pipeline)
- **SRE** (déploiement, idempotence)
- **Devs** (CI/CD et promotion)
- **Architectes** (design de Registry)

## Lecture recommandée

1. `ci-cd/pipeline-build-promotion.md` — Comprendre les 4 étapes
2. `registry/nexus-architecture.md` — Gouvernance et immuabilité
3. `orchestration/workflow-ansible.md` — Déploiement et orchestration
4. `orchestration/deploy-stack-contract.md` — Rôle générique
