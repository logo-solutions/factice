# ADR-0002 — Report de l'implémentation du SBOM au lot 1

- **Statut** : accepté, implémentation reportée (14/10/2026). Date de réévaluation : fin du lot 1 (à fixer).
- **Exigences liées** : spec `nexus-spec.md` §6.3 et §6.5, critère de recette R2 (une promotion sans SBOM échoue) ; ACC non concerné.

## Contexte

La spec rend le SBOM obligatoire pour toute promotion (R2). Le pilote Achera est le seul lot 1 ; la génération de SBOM (CycloneDX) dépend de la chaîne de build, qui n'est pas encore en place.

## Décision

Le SBOM n'est pas implémenté pour le lot 1. Les artefacts ingérés sans SBOM portent une **exception tracée** (« SBOM non produit »). La promotion vérifie le manifeste, pas le SBOM, jusqu'à implémentation.

## Alternatives écartées

- **Bloquer toute promotion sans SBOM** : impossible au lot 1 sans chaîne de build.
- **Générer un SBOM à la main** : contraire au principe de la spec (SBOM produit par la chaîne), et non reproductible.

## Conséquences

- R2 n'est couvert que pour le manifeste au lot 1.
- Chaque artefact sans SBOM doit être recensé : c'est le registre des dérogations, à mettre à jour.
- À l'implémentation : retirer l'exception et réactiver le contrôle R2 complet, par un ADR qui remplace celui-ci.
