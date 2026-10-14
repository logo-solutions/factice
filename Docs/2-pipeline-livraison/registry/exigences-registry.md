# Exigences du registry : nommage des dépôts et contrôle d'accès

Exigences dédiées au registry Nexus Repository Pro, pour le lot 1 (pilote `service.hra`). Elles précisent les exigences ACC (`Docs/exigences/10-controle-acces-segregation.md`) et les critères de recette de `nexus-spec.md` §11. Statut : **brouillon**, à valider.

## REG-01 — Nommage des dépôts et des chemins

**Énoncé.** Chaque dépôt du registry porte un nom qui indique son format et son cycle de vie, sans suffixe de version. Tout chemin d'artefact commence par l'identifiant de l'application (`service.hra` pour Achera).

**Pourquoi.** Retrouver les artefacts d'une application par son identifiant (critère R8), et éviter que la structure du registry dépende de l'équipe qui la gère.

| | |
|---|---|
| Priorité | DOIT |
| Applicabilité | Tout dépôt du registry |
| Preuve attendue | Liste des dépôts ; recherche par préfixe `service.hra` retourne tous les artefacts de l'application (R8) |
| Critère d'acceptation | Aucun dépôt ne porte de numéro de version dans son nom ; aucun artefact `service.hra` hors du préfixe |
| Réserve | Les règles complètes de nomenclature viendront plus tard ; cette exigence fixe seulement la structure et l'identifiant |
| Lien | ACC-01 (cloisonnement par périmètre) |

## REG-02 — Contrôle d'accès par rôles (RBAC)

**Énoncé.** L'accès au registry est accordé par rôle, à un périmètre applicatif. Un compte ne publie pas et ne promeut pas à la fois. Un accès anonyme est refusé.

**Pourquoi.** Limiter l'impact d'un compte compromis, et séparer la publication (candidat) de la promotion (release).

| | |
|---|---|
| Priorité | DOIT |
| Applicabilité | Tout le registry, au lot 1 |
| Preuve attendue | Matrice des rôles et des comptes ; tentative de publication hors rôle refusée ; tentative de promotion par le compte éditeur refusée ; accès anonyme refusé (R11) |
| Critère d'acceptation | Aucune action hors de son rôle n'aboutit ; chaque compte a exactement les rôles de sa matrice |
| Réserve | Comptes locaux au lot 1 ; connexion à l'annuaire à décider (ACC-05) |
| Lien | ACC-02 (rôles), ACC-03 (moindre privilège), ACC-04 (séparation des tâches), ACC-07 (comptes techniques) |
