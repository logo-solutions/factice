# Lot 1 – Registry Nexus Repository Pro (pilote service.hra)

Stories du lot 1, rédigées à partir de `nexus-spec.md`, avec les décisions prises le 14/10/2026 et révisées après relecture.
Chaque story a une section **Démo** : la manière de montrer qu'elle est terminée. Les commandes sont à valider sur l'instance avant la recette ; les points marqués **(à confirmer)** dépendent d'une décision encore ouverte.

Variables utilisées dans les démos :
- `NEXUS` : URL de base de l'instance (ex. `http://nexus.local:8081`)
- `APP` : identifiant de l'application, `service.hra`
- `USER_EDITEUR`, `USER_LECTEUR` : comptes de test, mots de passe dans le coffre (jamais dans ce fichier)

## Décisions retenues

- **Édition** : Nexus Repository Pro (et non Community). Voir [ADR-0001](../adr/0001-nexus-repository-pro.md).
- **Application pilote** : Achera, identifiant `service.hra`.
- **Formats** : raw et Docker.
- **SBOM** : obligatoire dès le lot 1 (spec §6.5, critère R2). [ADR-0002](../adr/0002-sbom-reporte.md) a été abrogé le 15/10/2026 : le report et l'exception tracée n'existent plus.
- **Haute disponibilité** : reportée (la spec la prévoit avec Pro, voir §10.1 ; [ADR-0003](../adr/0003-haute-disponibilite-reportee.md)).
- **Gestion** : manuelle dans un premier temps, avec un runbook. La reproduction par `roles/nexus` viendra plus tard.
- **CMDB** : alimentation plus tard. Les critères R7 à R9 ne sont pas dans ce lot.
- **Nomenclature complète** : plus tard. Seul l'identifiant `service.hra` est fixé.
- **Hors périmètre** (infrastructure, traitée par ailleurs) : sauvegarde et restauration (R10), supervision et seuils d'alerte disque, rétention et nettoyage du candidat.

## État d'avancement (2026-10-19)

Instance réelle : conteneur `nexus` (image `sonatype/nexus3:3.96.3`, **édition Community**). Le présent document exige Pro : l'écart est **ouvert** (licence Pro, ou révision de la décision). Données dans `/Volumes/HDD6/02-Chaude/nexus/nexus-data`, instance réinitialisée le 2026-10-18 (anciennes données mises de côté). Accès : `127.0.0.1:8081` et Tailscale `100.113.214.55:8081`.

**Dépôts** (nom `factice.app` pour l'instant)

| Dépôt | Type | Port | Blob store | Politique |
|---|---|---|---|---|
| `docker-candidat` | docker hosted | 8082 | `docker-candidat` | Allow redeploy |
| `docker-release` | docker hosted | 5002 | `docker-release` | Disable redeploy |
| `raw-candidat` | raw hosted | HTTP | `raw-candidat` | Allow redeploy |

**Comptes** (un par usage ; mots de passe dans Bitwarden et `vault.yml`, jamais dans le dépôt)

| Compte | Rôle | Usage |
|---|---|---|
| `ci-logo` | `ci-candidat-push` | Build manuel, tests |
| `svc-promotion` | `svc-promotion` | Promotion candidat vers release |
| `svc-deploiement` | `svc-deploiement` | Lecture de la release |
| `svc-build-factice-app` | `svc-build-factice-app` (créé le 2026-10-19) | Build de la CI `factice`. Connexion à tester |
| `admin` | administrateur | Administration uniquement, jamais dans la CI |

**Statut des stories**

| Story | Statut | Commentaire |
|---|---|---|
| S1 Dépôts et blob stores | Fait | Ports 8082 et 5002 vérifiés (`401` sans compte) |
| S2 Préfixe et sélecteur `service.hra` | À décider | Propre au pilote Achera |
| S3 Rôles et comptes | Partiel | Rôles en place ; accès anonyme refusé par configuration, à tester dans l'interface |
| S4 Ingestion manuelle | Fait | Push de test sur le candidat |
| S5 Manifeste de release | À faire | Modèle défini (§6.4 du spec) |
| S6 Promotion candidat vers release | Partiel | Le compte `svc-promotion` pousse dans la release ; promotion réelle depuis le candidat non testée |
| S7 Release immuable | Fait | Second push refusé (`redeploy is not allowed`) |
| S8 Nettoyage | Hors lot 1 | Politique « candidat 7 jours » créée, non attachée ; à traiter dans l'infrastructure |
| S9 Supervision | Hors lot 1 | Plan : sonde `/service/rest/v1/status`, alerte disque |
| S10 Runbook | À faire | À rédiger à partir des étapes réelles |

**Pipeline CI** (`ci.yml`) : le job `build` tourne sur le runner `macmini-factice` (en ligne) et publie image, SBOM et manifeste. Restent à faire : passer le compte de build à `svc-build-factice-app` (le secret `NEXUS_BUILD_PASSWORD` doit alors être celui de ce compte) et corriger la variable `NEXUS_DOCKER_CANDIDAT` (`localhost:5001` au lieu de `8082`), en PR.

**Reste à faire, par ordre** : tester la connexion de `svc-build-factice-app` ; PR `ci.yml` ; attacher la politique de nettoyage (S8) ; supprimer les images de test (`factice.app/test-ci` dans le candidat, `factice.app/test-s7` dans la release, par l'administrateur seulement) ; trancher l'édition (Pro ou Community) ; S5, S10.

## Epic : Lot 1 – Registry Nexus Pro

### S1 – Dépôts pour Achera
En tant que responsable plateforme, je veux des dépôts candidat et release pour les formats raw et Docker, afin de cadrer le stockage dès le départ.
- Les dépôts suivent la matrice de la spec (§3.1) pour raw et Docker.
- Création à la main selon un runbook. La même configuration doit pouvoir être reproduite plus tard par `roles/nexus`.
- Les dépôts release sont en politique d'écriture refusant tout remplacement (voir S7). **Précision** : la politique à utiliser est `ALLOW_ONCE`, pas `DENY`, sinon la promotion elle-même serait bloquée (voir Revue, point 4).

**Démo**
1. Lister les dépôts : `curl -u $USER_LECTEUR "$NEXUS/service/rest/v1/repositories"` → présence de `raw-candidat`, `raw-release`, `docker-candidat`, `docker-release`.
2. Vérifier la politique d'écriture de chaque release : `curl -u $USER_LECTEUR "$NEXUS/service/rest/v1/repositories/raw-release"` → `writePolicy` = `ALLOW_ONCE`.
3. Docker : `docker login docker-candidat.<hôte>` (le nom dépend du routage, **à confirmer** : spec §3.3) → connexion réussie.

### S2 – Chemin et sélecteur de contenu `service.hra`
En tant que responsable de la gouvernance, je veux que tout artefact d'Achera soit sous le préfixe `service.hra`, afin qu'une application ne puisse publier que sous son identifiant (critère R4).
- Un sélecteur de contenu limite les dépôts Achera au préfixe, pour raw comme pour Docker (chemin selon la spec §4.2).
- Une publication sous un autre préfixe est refusée.

**Démo**
1. Publier sous le préfixe : `curl -u $USER_EDITEUR --upload-file test.txt "$NEXUS/repository/raw-candidat/service.hra/app/1.0.0/test.txt"` → `201`.
2. Publier sous un autre préfixe : même commande vers `.../raw-candidat/autre-app/1.0.0/test.txt` → refus (`403`).
3. Vérifier le sélecteur : `curl -u $USER_LECTEUR "$NEXUS/service/rest/v1/security/content-selectors"` → expression du type `path =^ "/service.hra/"`, rattachée aux dépôts Achera.

### S3 – Rôles et comptes (RBAC)
En tant que responsable de la sécurité, je veux les rôles de la spec (§5.1) en place, afin que chacun n'ait que les droits nécessaires.
- Rôles : `lecteur`, `editeur` (candidat `service.hra`), compte de promotion, `mutualise-editeur`, `ssi-controle`, `exploitation`.
- Un accès anonyme est refusé (critère R11).
- Comptes locaux tant que l'annuaire d'entreprise n'est pas connecté. **Écart avec la spec** : §5.1 prévoit le SSO ; voir Revue, point 6.

**Démo**
1. Anonyme refusé : `curl -I "$NEXUS/repository/raw-release/service.hra/app/1.0.0/test.txt"` → `401` ou `403`, et `curl -s "$NEXUS/service/rest/v1/security/anonymous"` → `"enabled": false`.
2. Lecteur en lecture seule : `curl -u $USER_LECTEUR -X PUT --upload-file test.txt "$NEXUS/repository/raw-candidat/service.hra/app/1.0.0/test.txt"` → refus.
3. Éditeur limité au candidat : même PUT avec `$USER_EDITEUR` vers `raw-release` → refus ; vers `raw-candidat` → `201`.
4. Chaque rôle de la liste existe : `curl -u $USER_EXPLOITATION "$NEXUS/service/rest/v1/security/roles"` → les six rôles présents.

### S4 – Ingestion manuelle dans le candidat
En tant que développeur Achera, je veux téléverser un artefact et son SBOM dans le candidat selon un runbook, afin de tester le registry avant toute automatisation.
- Le chemin commence par `service.hra`.
- L'artefact est téléchargeable, avec son empreinte SHA-256.
- Le SBOM est joint à l'artefact (spec §6.5). **Dépend de ADR-0002** : tant que le SBOM est reporté, l'artefact porte une exception « SBOM non produit » inscrite au registre des dérogations.

**Démo**
1. Téléverser l'artefact et son SBOM (`app-1.0.0.cdx.json`) sous `service.hra/app/1.0.0/`.
2. Télécharger et comparer l'empreinte : `curl -u $USER_LECTEUR -s "$NEXUS/repository/raw-candidat/service.hra/app/1.0.0/app.tgz" | sha256sum` doit égaler `sha256` renvoyé par `curl -u $USER_LECTEUR "$NEXUS/service/rest/v1/search?repository=raw-candidat&name=service.hra/app/1.0.0/app.tgz"`.
3. Vérifier la présence du SBOM à côté : même recherche sur `app-1.0.0.cdx.json`.

### S5 – Manifeste de release et attestations signées
En tant qu'auditeur, je veux un manifeste par artefact (version, empreinte, date, source, SBOM) et des attestations signées qui le lient à l'artefact, afin de vérifier ce qui est promu sans faire confiance à un document saisi à la main.
- Le manifeste suit les champs de la spec (§6.4).
- Le SBOM et la provenance sont attachés à l'artefact comme attestations, signées (signature keyless, type Cosign ou équivalent).
- La signature est vérifiée avant promotion (intégrée à S6).

**Démo**
1. Ouvrir le manifeste : `curl -u $USER_LECTEUR "$NEXUS/repository/raw-candidat/service.hra/app/1.0.0/app-1.0.0.manifest.json"` → champs de la spec §6.4 présents : `application`, `composant`, `version`, `build`, `commit`, `dateCommit`, `origineSbom`.
   Nommage (spec §6.4 et §6.5) : `<composant>-<version>.manifest.json` et `<composant>-<version>.cdx.json`, rangés à côté de l'artefact.
2. Vérifier la signature (**à confirmer** : Cosign ne signe pas nativement un fichier raw ; méthode probable `cosign verify-blob --bundle`, ou attestation OCI si l'artefact est une image) :
   `cosign verify-blob --bundle app.tgz.sigstore.json --certificate-identity <identité du workflow> --certificate-oidc-issuer <émetteur> app.tgz` → `Verified OK`.
3. Modifier un octet de l'artefact et relancer la vérification → échec attendu.

### S6 – Promotion candidat vers release
En tant que responsable de la release, je veux promouvoir un artefact du candidat vers la release, afin qu'il soit figé.
- Docker : la promotion se fait par digest (les tags sont mutables). Raw : méthode selon ce que Nexus Pro supporte (point §12 de la spec, à vérifier).
- L'empreinte est identique avant et après la promotion.
- Une promotion sans manifeste ou sans SBOM échoue (R2). SBOM obligatoire dès le lot 1 (ADR-0002, abrogé le 15/10/2026) : le SBOM doit donc être produit par la chaîne de build.

**Démo**
1. Docker : noter le digest du candidat `crane digest docker-candidat.<hôte>/service.hra/app@<digest>`, copier par digest vers `docker-release` (`skopeo copy --all docker://…@<digest> docker://docker-release.<hôte>/service.hra/app@<digest>`), puis vérifier que le digest est identique côté release.
2. Raw, repli par republication contrôlée (spec §12, démontrable dès maintenant) :
   - `sha256sum app.tgz` puis `curl -u $USER_LECTEUR -s "$NEXUS/service/rest/v1/search?repository=raw-candidat&name=service.hra/app/1.0.0/app.tgz"` : noter le `sha256` du candidat.
   - Republier le même fichier, avec son manifeste et son SBOM, dans `raw-release` : `curl -u $USER_PROMO --upload-file app.tgz "$NEXUS/repository/raw-release/service.hra/app/1.0.0/app.tgz"`.
   - Vérifier que le `sha256` côté release est identique à celui du candidat.
3. Promotion sans manifeste, puis sans SBOM : tenter avec un candidat incomplet → échec attendu pour chacun (R2).

### S7 – Immutabilité de la release
En tant que responsable de la release, je veux qu'un artefact publié en release ne puisse pas être remplacé, afin de garantir ce qui a été déployé.
- Une tentative de republication sur un chemin existant est refusée (R1).

**Démo**
1. Publier une fois : `curl -u $USER_PROMO --upload-file app.tgz "$NEXUS/repository/raw-release/service.hra/app/1.0.0/app.tgz"` → `201`.
2. Republier le même chemin, avec un contenu différent : même commande → refus attendu (code exact à constater sur l'instance).
3. Vérifier que le contenu d'origine n'a pas changé : empreinte identique à celle de S4.

### S8 – Supervision de base
En tant qu'exploitant, je veux une sonde de santé, afin de détecter une panne.
- La sonde de santé répond.
- Périmètre : sonde de santé et contrôle d'écriture uniquement. Les autres éléments de la spec §10.3 sont hors lot 1 (voir Idea).

**Démo**
1. `curl -s -o /dev/null -w "%{http_code}\n" "$NEXUS/service/rest/v1/status"` → `200`.
2. `curl -s -o /dev/null -w "%{http_code}\n" "$NEXUS/service/rest/v1/status/writable"` → `200` (dépôts accessibles en écriture).
3. Constater l'échec : arrêter le conteneur de test (hors production) → la sonde ne répond plus.

### S9 – Runbook d'exploitation
En tant qu'exploitant, je veux un runbook couvrant création de dépôt, ajout d'utilisateur et promotion, afin de travailler sans connaître Nexus par cœur.
- **Critère de recette** : une personne qui n'a jamais utilisé Nexus réalise seule les trois opérations ci-dessous, sur l'instance de test, en moins de 60 minutes, sans poser de question à l'auteur du runbook. Toute étape ambiguë relevée pendant l'exercice est corrigée dans le runbook.

**Démo**
1. Un opérateur (ou un relecteur) suit le runbook à blanc, chronomètre, et note chaque étape ambiguë.
2. Trois opérations à réussir : créer un dépôt de test, ajouter un utilisateur avec le rôle `editeur`, promouvoir un artefact.
3. Le runbook est corrigé à partir des points notés, puis rejoué une fois.

### S10 – Provenance de la promotion (R3)
En tant que responsable de la release, je veux qu'une promotion échoue si le commit source n'appartient pas à une branche protégée, afin que seul du code relu soit promu.
- Un candidat dont le commit est inconnu ou hors branche protégée est refusé (R3).

**Démo**
1. Pousser un commit sur une branche non protégée, publier un candidat depuis ce commit, tenter la promotion → refus attendu.
2. Publier un candidat depuis un commit de la branche protégée (`main`) → promotion acceptée.
3. Préalable (à configurer côté hébergeur Git, pas dans Nexus) : `main` est une branche protégée, avec pull request obligatoire, statut CI requis, pas de force-push ni de suppression.
4. Vérification de provenance, à intégrer à la promotion : le commit du candidat doit être un ancêtre de `origin/main` → `git merge-base --is-ancestor <sha> origin/main` retourne 0. Sinon, refus.

### S11 – Proxy et groupes de lecture
En tant que développeur Achera, je veux tirer les dépendances publiques et les releases d'Achera par un point d'accès unique, afin de ne consommer que du contenu contrôlé (spec §3.1, §3.2).
- Les proxys (`docker-proxy-public` et, plus tard, `maven-proxy-central`, `npm-proxy-npmjs`) mettent en cache les dépendances publiques. Aucun push n'est possible vers un proxy.
- Les groupes `docker-all` (et équivalents) exposent release et proxy en lecture. Le candidat n'appartient à aucun groupe consommé.
- Un déploiement ne tire jamais directement depuis le candidat ni depuis le proxy.

**Démo**
1. Configuration du groupe : `curl -u $USER_LECTEUR "$NEXUS/service/rest/v1/repositories/docker/group/docker-all"` → `memberNames` contient `docker-release` et `docker-proxy-public`, et ne contient pas `docker-candidat` (**à valider**, endpoint à confirmer sur Pro).
2. Tirage via le groupe : `docker pull docker-all.<hôte>/library/alpine:<tag>` → réussi (**routage Docker à confirmer**, spec §3.3).
3. Push refusé sur le proxy : `docker push docker-proxy-public.<hôte>/…` → refus attendu.
4. Tirage du candidat depuis un déploiement : `docker pull docker-candidat.<hôte>/service.hra/app:<tag>` avec un compte de déploiement → refus attendu (le compte de déploiement n'a accès qu'à la release).

### S12 – Comptes de service et jetons de build
En tant que responsable de la sécurité, je veux des comptes de service par application et un compte en lecture seule pour le déploiement, afin qu'aucun script ne porte un compte nominatif (spec §5.2).
- Un compte de service par application (`svc-build-service.hra`) pour la chaîne de build, avec jeton d'accès stocké dans le coffre d'entreprise, et rotation périodique.
- Un compte de service en lecture seule pour le pipeline de déploiement, limité aux dépôts release.
- Aucun compte nominatif dans les scripts de build ; aucun secret en clair dans le dépôt.

**Démo**
1. Le build publie avec son jeton, pas avec un compte personnel : `curl -u svc-build-service.hra:$TOKEN --upload-file app.tgz "$NEXUS/repository/raw-candidat/service.hra/app/1.0.1/app.tgz"` → `201`.
2. Le compte de déploiement ne peut pas publier : `curl -u svc-deploy:$TOKEN_DEPLOY -X PUT --upload-file app.tgz "$NEXUS/repository/raw-release/service.hra/app/1.0.1/app.tgz"` → refus.
3. Le compte de déploiement lit la release : `curl -u svc-deploy:$TOKEN_DEPLOY -I "$NEXUS/repository/raw-release/service.hra/app/1.0.0/app.tgz"` → `200`.
4. Rotation : générer un nouveau jeton, mettre à jour le coffre, relancer le build → réussi ; l'ancien jeton → `401`.
5. Contrôle du dépôt : `grep -rn "password\|token" <dépôt de build>` ne trouve aucun secret en clair.

### S13 – Recherche par préfixe (R8)
En tant que responsable de la gouvernance, je veux retrouver tous les artefacts d'une application par son identifiant, dans chaque dépôt hébergé, afin de faire un inventaire et un audit (critère R8).
- Une recherche sur `service.hra` renvoie tous les artefacts publiés sous ce préfixe dans candidat et release, et aucun autre.
- Le résultat inclut le chemin, l'empreinte SHA-256 et la version.

**Démo**
1. Lister les artefacts du candidat : `curl -u $USER_LECTEUR "$NEXUS/service/rest/v1/assets?repository=raw-candidat"` (suivre le `continuationToken` jusqu'à la fin), puis filtrer les chemins commençant par `service.hra/`.
2. Faire la même chose sur `raw-release`.
3. Comparer au décompte attendu, publié dans le registre de l'application. Aucun artefact d'une autre application ne doit apparaître.

### S14 – Composant éditeur (COTS, R6)
En tant que responsable de la release, je veux déposer un composant éditeur avec un SBOM reconstitué et marqué comme tel, afin de le promouvoir comme les composants internes sans prétendre qu'il vient de notre chaîne de build (spec §6.2, R6).
- Le composant est déposé, pas proxifié. Son empreinte est comparée à celle publiée par l'éditeur.
- Le SBOM est reconstitué par nos soins et porte la propriété `origine = reconstitué par analyse` (spec §6.2). Le manifeste porte `origineSbom = reconstitue` (spec §6.4).
- Chemin (spec §4.2) : composant partagé sous `mutualise/<composant>/<version>/` ; composant propre à une application sous `<identifiant>/<composant>/<version>/`. La version est celle de l'éditeur, inchangée (D2).
- La promotion suit les contrôles du §6.3 pour les COTS : empreinte conforme, manifeste sans commit, SBOM marqué, analyse licences et vulnérabilités sans blocage.
- Hypothèse de formats à confirmer (spec §12) : Temurin, MongoDB, MariaDB en raw.

**Démo**
1. Déposer le composant de test et son SBOM reconstitué dans `raw-candidat`, sous `mutualise/temurin/21.0.5/` (exemple ; le composant de test réel reste à choisir).
2. Comparer l'empreinte : `sha256sum composant.tgz` doit égaler la valeur publiée par l'éditeur.
3. Vérifier le marqueur dans le SBOM : `jq '.metadata.properties[] | select(.name=="origine")' temurin-21.0.5.cdx.json` → `value` = `reconstitué par analyse`. Vérifier aussi `origineSbom` = `reconstitue` dans le manifeste.
4. Promouvoir (méthode du repli, S6) : réussi si les contrôles passent ; échec si la licence est interdite (R5, après quarantaine) ou si le SBOM n'est pas marqué.

## Idea (hors lot 1)

- **Pare-feu de dépôt / quarantaine à l'entrée** (spec §2, critère R5) : à traiter plus tard, avec la couverture du format raw à confirmer auprès de l'éditeur. Voir Revue, point 7.
- **Sauvegarde et restauration** (spec §10.1, R10) : infrastructure, hors périmètre de ce lot. Voir Revue, point 8.
- **Supervision au-delà de la sonde** (spec §10.3) : espace disque et seuils, latence du proxy, quarantaines en attente, journal d'audit. Hors lot 1, à reprendre avec la supervision de l'infrastructure.

## Revue contradictoire (avocat du diable)

Ces points disent ce qui manque ou ne tient pas. Ils ne sont pas tranchés ici.

1. **SBOM : résolu le 15/10/2026.** ADR-0002 est abrogé, dans le sens « pas de report ». Il reste une conséquence ouverte : la chaîne de build qui produit le SBOM n'existe pas encore, donc aucun artefact ne peut être promu tant qu'elle n'est pas livrée.
2. **Édition : `Docs/decisions.md` dit encore Community.** Ce fichier et ADR-0001 disent Pro. À corriger dans `decisions.md`.
3. **Promotion raw : méthode officielle non tranchée** (spec §12). Le repli par republication contrôlée par empreinte est démontrable dès maintenant (démo S6, étape 2). Reste à savoir si Nexus Pro offre une promotion native raw, et si le repli devient la méthode retenue.
4. **Immutabilité : mauvaise politique possible.** S1 dit « refusant tout remplacement ». `DENY` bloquerait aussi la première publication, donc la promotion. `ALLOW_ONCE` est le réglage cohérent, mais il faut le confirmer sur Pro.
5. **Formats absents sans justification.** Maven et npm sont dans la matrice de la spec (§3.1), et Python/PyPI n'est nulle part. Une exclusion explicite du lot 1 est nécessaire, avec la date de reprise.
6. **Annuaire.** La spec (§5.1) impose le SSO, S3 accepte des comptes locaux. Il manque un compte de secours documenté, une date de sortie des comptes locaux, et un ADR si l'écart dure.
7. **R5 (quarantaine) reportée alors que la spec le demande en recette.** La recette ne peut donc pas être complète au lot 1 : il faut le noter explicitement comme non couvert.
8. **R10 (restauration) hors périmètre**, alors que la spec dit Nexus « composant critique ». Au minimum, une sauvegarde avant toute démo ou toute donnée réelle, et un test de restauration à planifier.
9. **Manques de stories : comblés par S11 à S14** (proxy et groupes, comptes de service, recherche par préfixe R8, COTS R6). Leurs démos contiennent des endpoints et marqueurs **à valider** sur l'instance. L'hypothèse de formats (spec §12) range Temurin, MongoDB et MariaDB en raw : elle reste à confirmer.
10. **Routage Docker : sous-domaine par dépôt (ADR-0005, proposé).** Les démos Docker de S1, S6 et S11 utilisent ce modèle ; le domaine réel reste à renseigner à la place de `<hôte>`.
11. **S8 : périmètre tranché.** La sonde de santé et le contrôle d'écriture sont dans le lot 1 ; les autres éléments de §10.3 sont déclarés hors lot 1 (voir Idea).
12. **S10 : prérequis défini.** Branche `main` protégée côté Git, et vérification de provenance par `merge-base --is-ancestor` (voir démo S10).

## À confirmer avant de finaliser

- **Annuaire d'entreprise** : les comptes locaux suffisent-ils pour le lot 1 ? (voir point 6)
- **Méthode de promotion raw** (spec §12).
- **Routage Docker** : sous-domaine par dépôt, proposé dans ADR-0005 ; domaine interne et certificat interne à renseigner.
- **Formats hors lot 1** : Maven, npm et Python sont-ils reportés explicitement ?
