# 1. Fondations : réseau et architecture

## Objectif

Comprendre comment les composants (CI/CD, Registry, Ansible, hôte) communiquent entre eux, les zones de sécurité, et l'isolation des environnements.

## Documents

| Document | Contenu |
|---|---|
| [flux-et-reseau.md](flux-et-reseau.md) | Flux réels du pipeline, diagramme avec frontières de confiance, chiffrement en transit |
| [flux-outils.md](flux-outils.md) | Flux cibles entre les outils de la chaîne (exigences, ITSM, GitLab, registry, CMDB, documentation) et décisions associées |
| [flux-outils-factice.md](flux-outils-factice.md) | Mise en œuvre dans factice : correspondance des outils, état de chaque flux, cycle d'un déploiement avec ITSM et CMDB |
| [zones-securite.md](zones-securite.md) | Zones de sécurité, frontières de confiance, accès d'administration, isolation des environnements |
| [modele-menaces.md](modele-menaces.md) | Analyse STRIDE aux frontières de confiance, mesures prioritaires |

## Pour qui ?

- **Architectes** (conception)
- **SRE / Ops** (compréhension du flux)
- **SecOps** (zones et segmentation)

## Avant de lire

Assurez-vous de comprendre :
- [architecture-3tiers.md](../architecture-3tiers.md) — Les trois tiers de factice
- [decisions.md](../decisions.md) — Pourquoi ces choix
