# 1. Fondations : réseau et architecture

## Objectif

Comprendre comment les composants (CI/CD, Registry, Ansible, CMDB, Vault) communiquent entre eux, les zones de sécurité, et l'isolation des environnements.

## Documents

| Document | Contenu |
|---|---|
| [flux-et-reseau.md](flux-et-reseau.md) | Flux entre registre, Ansible, CI/CD, CMDB, Vault et cibles de déploiement |
| [zones-securite.md](zones-securite.md) | Zones de sécurité, segmentation réseau, isolation |

## Pour qui ?

- **Architectes** (conception)
- **SRE / Ops** (compréhension du flux)
- **SecOps** (zones et segmentation)

## Avant de lire

Assurez-vous de comprendre :
- [architecture-3tiers.md](../architecture-3tiers.md) — Les trois tiers de factice
- [decisions.md](../decisions.md) — Pourquoi ces choix
