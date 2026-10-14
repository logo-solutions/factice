# Lot 1 – Registry Nexus Repository Pro (pilote service.hra)

Stories du lot 1, rédigées à partir de `nexus-spec.md`, avec les décisions prises le 14/10/2026 et révisées après relecture.

## Décisions retenues

- **Édition** : Nexus Repository Pro (et non Community).
- **Application pilote** : Achera, identifiant `service.hra`.
- **Formats** : raw et Docker.
- **SBOM** : obligatoire dès le lot 1 (spec §6.5, critère R2). Pas de report : un artefact sans SBOM n'est ni promu ni accepté.
- **Haute disponibilité** : reportée (la spec la prévoit avec Pro, voir §10.1).
- **Gestion** : manuelle dans un premier temps, avec un runbook. La reproduction par `roles/nexus` viendra plus tard.
- **CMDB** : alimentation plus tard. Les critères R7 à R9 ne sont pas dans ce lot.
- **Nomenclature complète** : plus tard. Seul l'identifiant `service.hra` est fixé.
- **Hors périmètre** (infrastructure, traitée par ailleurs) : sauvegarde et restauration (R10), supervision et seuils d'alerte disque, rétention et nettoyage du candidat.

## Epic : Lot 1 – Registry Nexus Pro

### S1 – Dépôts pour Achera
En tant que responsable plateforme, je veux des dépôts candidat et release pour les formats raw et Docker, afin de cadrer le stockage dès le départ.
- Les dépôts suivent la matrice de la spec (§3.1) pour raw et Docker.
- Création à la main selon un runbook. La même configuration doit pouvoir être reproduite plus tard par `roles/nexus`.
- Les dépôts release sont en politique d'écriture refusant tout remplacement (voir S7).

### S2 – Chemin et sélecteur de contenu `service.hra`
En tant que responsable de la gouvernance, je veux que tout artefact d'Achera soit sous le préfixe `service.hra`, afin qu'une application ne puisse publier que sous son identifiant (critère R4).
- Un sélecteur de contenu limite les dépôts Achera au préfixe, pour raw comme pour Docker (chemin selon la spec §4.2).
- Une publication sous un autre préfixe est refusée.

### S3 – Rôles et comptes (RBAC)
En tant que responsable de la sécurité, je veux les rôles de la spec (§5.1) en place, afin que chacun n'ait que les droits nécessaires.
- Rôles : `lecteur`, `editeur` (candidat `service.hra`), compte de promotion, `mutualise-editeur`, `ssi-controle`, `exploitation`.
- Un accès anonyme est refusé (critère R11).
- Comptes locaux tant que l'annuaire d'entreprise n'est pas connecté.

### S4 – Ingestion manuelle dans le candidat
En tant que développeur Achera, je veux téléverser un artefact et son SBOM dans le candidat selon un runbook, afin de tester le registry avant toute automatisation.
- Le chemin commence par `service.hra`.
- L'artefact est téléchargeable, avec son empreinte SHA-256.
- Le SBOM est joint à l'artefact (spec §6.5).

### S5 – Manifeste de release et attestations signées
En tant qu'auditeur, je veux un manifeste par artefact (version, empreinte, date, source, SBOM) et des attestations signées qui le lient à l'artefact, afin de vérifier ce qui est promu sans faire confiance à un document saisi à la main.
- Le manifeste suit les champs de la spec (§6.4).
- Le SBOM et la provenance sont attachés à l'artefact comme attestations, signées (signature keyless, type Cosign ou équivalent).
- La signature est vérifiée avant promotion (intégrée à S6).

### S6 – Promotion candidat vers release
En tant que responsable de la release, je veux promouvoir un artefact du candidat vers la release, afin qu'il soit figé.
- Docker : la promotion se fait par digest (les tags sont mutables). Raw : méthode selon ce que Nexus Pro supporte (point §12 de la spec, à vérifier).
- L'empreinte est identique avant et après la promotion.
- Une promotion sans manifeste ou sans SBOM échoue (R2).

### S7 – Immutabilité de la release
En tant que responsable de la release, je veux qu'un artefact publié en release ne puisse pas être remplacé, afin de garantir ce qui a été déployé.
- Une tentative de republication sur un chemin existant est refusée (R1).

### S8 – Supervision de base
En tant qu'exploitant, je veux une sonde de santé, afin de détecter une panne.
- La sonde de santé répond.

### S9 – Runbook d'exploitation
En tant qu'exploitant, je veux un runbook couvrant création de dépôt, ajout d'utilisateur et promotion, afin de travailler sans connaître Nexus par cœur.

### S10 – Provenance de la promotion (R3)
En tant que responsable de la release, je veux qu'une promotion échoue si le commit source n'appartient pas à une branche protégée, afin que seul du code relu soit promu.
- Un candidat dont le commit est inconnu ou hors branche protégée est refusé (R3).

## Idea (hors lot 1)

- **Pare-feu de dépôt / quarantaine à l'entrée** (spec §2, critère R5) : à traiter plus tard, avec la couverture du format raw à confirmer auprès de l'éditeur.
- **Sauvegarde et restauration** (spec §10.1, R10) : infrastructure, hors périmètre de ce lot.

## À confirmer avant de finaliser

- **Annuaire d'entreprise** : les comptes locaux suffisent-ils pour le lot 1 ?
