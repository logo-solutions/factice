# ADR-0001 — Nexus Repository Pro comme registry des artefacts

- **Statut** : accepté (14/10/2026)
- **Référence historique** : `Docs/decisions.md`, section 4 (configuration par Ansible) et `2-pipeline-livraison/registry/nexus-presentation.md` (option A)
- **Exigences liées** : ACC-01, ACC-02 (contrôle d'accès) ; spec `nexus-spec.md` §1 et §12

## Contexte

Le registry doit être le catalogue unique des artefacts publiés : immutabilité, promotion candidat vers release, contrôle des composants tiers, alimentation de la CMDB. Plusieurs formats coexistent (Maven, Docker, raw, COTS). La spec cible environ 60 applications.

## Décision

Retenir **Nexus Repository Pro** comme registry, avec les politiques natives de la plateforme (promotion, droits, blob stores).

## Alternatives écartées

- **Nexus Community** : pas de promotion native, pas de haute disponibilité, pas de pare-feu de dépôt. La promotion devrait être une republication contrôlée, comme dans `decisions.md`.
- **Autre registry** : non étudié à ce stade (voir `nexus-presentation.md`).

## Conséquences

- Coût de licence Pro à valider (ligne « Coût de licence » de la présentation).
- La promotion native par étiquette dépend des formats supportés (spec §12) ; un repli par republication reste possible.
- La haute disponibilité est disponible avec Pro, mais reportée (ADR-0003).
