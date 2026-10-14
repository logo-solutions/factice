# Lot 1 – Registry Nexus Repository Pro (pilote service.hra)

Stories du lot 1, rédigées à partir de `nexus-spec.md`, avec les décisions prises le 14/10/2026.

## Décisions retenues

- **Édition** : Nexus Repository Pro (et non Community).
- **Application pilote** : Achera, identifiant `service.hra`.
- **SBOM** : obligatoire selon la spec, mais son implémentation est reportée à plus tard. Tout artefact ingéré sans SBOM porte une exception tracée à retirer à l'implémentation.
- **Haute disponibilité** : reportée (la spec la prévoit avec Pro, voir §10.1).
- **Gestion** : manuelle dans un premier temps, avec un runbook. La reproduction par `roles/nexus` viendra plus tard.
- **CMDB** : alimentation plus tard. Les critères R7 à R9 ne sont pas dans ce lot.
- **Nomenclature complète** : plus tard. Seul l'identifiant `service.hra` est fixé.

## Epic : Lot 1 – Registry Nexus Pro

### S1 – Dépôts et blob stores pour Achera
En tant que responsable plateforme, je veux des dépôts candidat et release par format et par cycle de vie, avec un blob store dédié et un quota souple, afin de cadrer le stockage dès le départ.
- Les dépôts suivent la matrice de la spec (§3.1), pour les formats retenus par Achera.
- Création à la main selon un runbook. La même configuration doit pouvoir être reproduite plus tard par `roles/nexus`.
- Les dépôts release ne peuvent pas être supprimés par un nettoyage.

### S2 – Chemin et sélecteur de contenu `service.hra`
En tant que responsable de la gouvernance, je veux que tout artefact d'Achera soit sous le préfixe `service.hra`, afin qu'une application ne puisse publier que sous son identifiant (critère R4).
- Un sélecteur de contenu limite les dépôts Achera au préfixe.
- Une publication sous un autre préfixe est refusée.

### S3 – Rôles et comptes (RBAC)
En tant que responsable de la sécurité, je veux les rôles de la spec (§5.1) en place, afin que chacun n'ait que les droits nécessaires.
- Rôles : `lecteur`, `editeur` (candidat `service.hra`), compte de promotion, `mutualise-editeur`, `ssi-controle`, `exploitation`.
- Un accès anonyme est refusé (critère R11).
- Comptes locaux tant que l'annuaire d'entreprise n'est pas connecté.

### S4 – Ingestion manuelle dans le candidat
En tant que développeur Achera, je veux téléverser un artefact dans le candidat selon un runbook, afin de tester le registry avant toute automatisation.
- Le chemin commence par `service.hra`.
- L'artefact est téléchargeable, avec son empreinte SHA-256.
- SBOM non produit : l'artefact porte l'exception tracée (voir décisions).

### S5 – Manifeste de release (rédigé à la main)
En tant qu'auditeur, je veux un manifeste par artefact (version, empreinte, date, source), afin de savoir ce qui est promu.
- Rédigé à la main pour le lot 1.
- Les champs suivent la spec (§6.4).

### S6 – Promotion candidat vers release
En tant que responsable de la release, je veux promouvoir un artefact du candidat vers la release, afin qu'il soit figé.
- Méthode selon ce que Nexus Pro supporte pour les formats d'Achera (point §12 de la spec, à vérifier).
- L'empreinte est identique avant et après la promotion.
- Une promotion sans manifeste échoue (R2, partie manifeste). La partie SBOM viendra avec son implémentation.

### S7 – Immutabilité de la release
En tant que responsable de la release, je veux qu'un artefact publié en release ne puisse pas être remplacé, afin de garantir ce qui a été déployé.
- Une tentative de republication sur un chemin existant est refusée (R1).

### S8 – Nettoyage et rétention
En tant que responsable plateforme, je veux une politique de nettoyage du candidat, afin de maîtriser le stockage sans jamais toucher à la release.
- Durée de rétention du candidat à fixer (valeur à confirmer).
- La release est exclue du nettoyage.

### S9 – Supervision de base
En tant qu'exploitant, je veux une sonde de santé et des alertes sur l'espace disque, afin de détecter une panne ou une saturation.
- La sonde de santé répond.
- Une alerte est déclenchée avant saturation du stockage.

### S10 – Runbook d'exploitation
En tant qu'exploitant, je veux un runbook couvrant création de dépôt, ajout d'utilisateur, promotion et restauration, afin de travailler sans connaître Nexus par cœur.

## À confirmer avant de finaliser

- **Formats d'Achera** : Maven, Docker, raw ou autre ? Cela change S1, S2 et S6.
- **Annuaire d'entreprise** : les comptes locaux suffisent-ils pour le lot 1 ?
- **Sauvegarde et restauration** : demandées par la spec (§10.1 et R10). Dans le lot 1 ou plus tard ?
- **Pare-feu de dépôt (quarantaine)** : nécessaire pour Achera dès le lot 1, ou plus tard ?
- **Rétention du candidat** : durée à fixer (S8).
