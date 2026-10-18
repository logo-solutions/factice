# ADR-0002 — SBOM obligatoire dès le lot 1 (report abandonné)

- **Statut** : abrogé le 15/10/2026. Remplacé par la décision ci-dessous : le SBOM est obligatoire dès le lot 1, sans exception.
- **Décision initiale** : 14/10/2026 (report du SBOM, exception tracée). Conservée plus bas pour l'historique.
- **Exigences liées** : spec `nexus-spec.md` §6.3 et §6.5, critère de recette R2 (une promotion sans SBOM échoue) ; ACC non concerné.

## Décision (15/10/2026)

Le SBOM est **obligatoire dès le lot 1** (spec §6.5, R2). Un artefact sans SBOM n'est ni ingéré dans le candidat comme artefact complet, ni promu. Il n'y a plus d'exception « SBOM non produit » ni de registre de dérogations pour ce point.

La promotion vérifie donc le manifeste **et** le SBOM, conformément à R2.

## Conséquences

- R2 est couvert en entier au lot 1. Les stories S4 et S6 de `nexusus.md` doivent être lues en ce sens.
- **Le SBOM doit être produit par la chaîne de build**, qui n'existe pas encore. Tant qu'elle n'est pas en place, aucun artefact ne peut être promu. Le lot 1 est donc bloqué côté build tant que cette chaîne n'est pas livrée.
- La génération manuelle reste écartée : elle n'est pas reproductible et contredit le principe de la spec (SBOM produit par la chaîne).
- Le registre des dérogations SBOM ne sert plus pour le lot 1. Les artefacts déjà ingérés sans SBOM doivent être soit complétés, soit retirés du candidat.

## Alternatives écartées

- **Reporter le SBOM au lot 2** (décision initiale) : retirée. Elle laissait la promotion sans contrôle R2 pendant tout le pilote, alors que l'audit en dépend.
- **Générer un SBOM à la main** : contraire au principe de la spec, et non reproductible.

## Historique — décision initiale (14/10/2026, abrogée)

> Le SBOM n'est pas implémenté pour le lot 1. Les artefacts ingérés sans SBOM portent une **exception tracée** (« SBOM non produit »). La promotion vérifie le manifeste, pas le SBOM, jusqu'à implémentation.
>
> Motif : la génération de SBOM (CycloneDX) dépend de la chaîne de build, qui n'était pas encore en place.
