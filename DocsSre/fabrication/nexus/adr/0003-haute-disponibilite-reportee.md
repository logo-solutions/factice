# ADR-0003 — Report de la haute disponibilité au lot 1

- **Statut** : accepté, implémentation reportée (14/10/2026). Date de réévaluation : fin du lot 1 (à fixer).
- **Exigences liées** : spec `nexus-spec.md` §10.1 et critère de recette R10 (restauration) ; ACC non concerné.

## Contexte

Nexus Pro offre la haute disponibilité (base externe, stockage de blobs partagé, répartiteur de charge). Le lot 1 ne porte que sur un pilote, géré à la main.

## Décision

Pas de haute disponibilité au lot 1 : une seule instance. La sauvegarde et le test de restauration restent à décider (question ouverte dans `nexusus.md`).

## Alternatives écartées

- **Haute disponibilité dès le lot 1** : coût d'infrastructure (base externe, stockage partagé) disproportionné pour un pilote.

## Conséquences

- Indisponibilité du registry = arrêt des livraisons de l'application pilote. À documenter dans le runbook (S10).
- À la mise en production d'une autre application : réévaluer cet ADR.
