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

## État d'avancement (2026-10-19)

Instance réelle : conteneur `nexus` (image `sonatype/nexus3:3.96.3`, **édition Community**, pas Pro : voir l'écart ci-dessous), Mac mini, base H2 embarquée, données dans `/Volumes/HDD6/02-Chaude/nexus/nexus-data`. Réinitialisée le 2026-10-18 (instance neuve, anciennes données mises de côté). Accès : `127.0.0.1:8081` et Tailscale `100.113.214.55:8081`.

**Écart à traiter** : la décision « Nexus Pro » ne peut pas être appliquée sur l'image actuelle (Community). À trancher avant la fin du lot : licence Pro, ou révision de la décision.

**Dépôts et stockage (remplacent le pilote Achera pour l'instant, nom `factice.app`)**

| Dépôt | Type | Port | Blob store | Politique de déploiement |
|---|---|---|---|---|
| `docker-candidat` | docker hosted | 8082 | `docker-candidat` | Allow redeploy |
| `docker-release` | docker hosted | 5002 | `docker-release` | Disable redeploy |
| `raw-candidat` | raw hosted | (HTTP) | `raw-candidat` | Allow redeploy (existe, répond `401` sans compte) |

Le blob store `default` existe mais n'est utilisé par aucun dépôt.

**Comptes (un par usage, mots de passe dans Bitwarden et `vault.yml`, jamais dans le dépôt)**

| Compte | Rôle | Usage |
|---|---|---|
| `ci-logo` | `ci-candidat-push` | Build manuel, tests |
| `svc-promotion` | `svc-promotion` | Promotion candidat vers release |
| `svc-deploiement` | `svc-deploiement` | Lecture de la release |
| `svc-build-factice-app` | `svc-build-factice-app` (candidat + raw-candidat), créé le 2026-10-19 | Build de la CI `factice` ; connexion à tester, pas encore vérifiée |
| `admin` | administrateur | Administration uniquement, jamais dans la CI |

**Statut des stories**

| Story | Statut | Commentaire |
|---|---|---|
| S1 Dépôts et blob stores | Fait | Vérifié (ports 8082 et 5002 répondent `401` sans compte) |
| S2 Préfixe et sélecteur `service.hra` | Non appliqué | Propre au pilote Achera, à décider pour `factice.app` |
| S3 Rôles et comptes | Partiel | Rôles en place. Accès anonyme refusé par configuration, pas encore testé dans l'interface |
| S4 Ingestion manuelle | Fait | Push de test sur le candidat (image de test à supprimer) |
| S5 Manifeste de release | Non fait | Modèle défini (§6.4 du spec), à rédiger pour une vraie image |
| S6 Promotion candidat vers release | Partiel | Le compte `svc-promotion` pousse dans la release, mais la promotion réelle depuis le candidat n'est pas testée |
| S7 Release immuable | Fait | Vérifié : second push refusé (`redeploy is not allowed`) |
| S8 Nettoyage et rétention | Configuré | Politique « candidat 7 jours » à attacher à `docker-candidat`, tâches planifiées 03 h 00 et 03 h 30 à vérifier au premier passage |
| S9 Supervision | Non fait | Plan : sonde `/service/rest/v1/status` et alerte d'espace disque (ntfy) |
| S10 Runbook | Non fait | À rédiger à partir des étapes réelles ci-dessus |

**Pipeline CI (`ci.yml`)** : le job `build` tourne sur le runner `macmini-factice` (self-hosted, en ligne) et publie image, SBOM et manifeste. Il reste deux blocages :
1. le compte `svc-build-factice-app` doit être créé (voir tableau des comptes) ;
2. le dépôt `raw-candidat` doit exister (fait) et recevoir ce compte.

Corrections à porter en PR sur `ci.yml` : nom du compte de build, et variable de dépôt `NEXUS_DOCKER_CANDIDAT` (valeur `localhost:5001` au lieu de `localhost:8082`).

**Secrets GitHub (`logo-solutions/factice`)** : `NEXUS_BUILD_PASSWORD`, `NEXUS_PROMOTION_PASSWORD`, `NEXUS_DEPLOY_PASSWORD` à jour (2026-10-18). `NEXUS_BUILD_PASSWORD` sert actuellement au compte `ci-logo` ; à remplacer quand `svc-build-factice-app` existe.

**Reste à faire, par ordre**
1. Créer `svc-build-factice-app` (rôle et utilisateur).
2. PR sur `ci.yml` (compte, variable), puis test sur une branche.
3. Attacher la politique de nettoyage à `docker-candidat`, vérifier les tâches planifiées.
4. Supprimer les images de test (`factice.app/test-ci` dans le candidat, `factice.app/test-s7` dans la release, cette dernière seulement par l'administrateur).
5. Décision sur l'édition (Pro ou Community).
6. S5, S9, S10.

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
