# To-do — registry et documentation

## ADR à rédiger

- [ ] **ADR-0005 — Emplacement de la documentation produit.** Proposition : documentation produit dans GitLab (docs-as-code, relue par merge request, versionnée avec le code). Confluence et le wiki GitLab sont écartés. Décision à acter.
- [ ] **ADR-0006 — Outil de suivi des exigences.** Aujourd'hui : fichier Excel. Cible à décider : OpenProject (suivi) avec le texte dans Git. Justifier le passage et la migration.
- [ ] **ADR-0007 — Génération du changelog.** Outil (git-cliff, release-please, autre) et source (commits, identifiants d'exigences et de work packages).

## Décisions en attente

- [ ] Accepter ADR-0004 (nommage des dépôts et RBAC).
- [ ] Achera : format de livraison (Maven, Docker, raw) pour fixer les dépôts.
- [ ] Annuaire d'entreprise : connecter au lot 1, ou comptes locaux.
- [ ] Sauvegarde et restauration : dans le lot 1 ou plus tard.
- [ ] Pare-feu de dépôt (quarantaine) : dans le lot 1 ou plus tard.
- [ ] Dates de réévaluation des ADR-0002 et ADR-0003 (fin du lot 1).

## Documentation et outils

- [ ] Schéma « Flux et outils » : renommer la boîte GitLab en « Forge (GitLab) : code, merge requests, documentation produit ».

- [ ] Migrer les procédures d'exploitation de la KB vers Git, et les publier dans le portail self-help de l'ITSM.
- [ ] Vérifier si l'ITSM a déjà un module de base de connaissances, avant de créer un second portail.
- [ ] Définir le statut documentaire (brouillon, validé, obsolète) et le relecteur de chaque document.
