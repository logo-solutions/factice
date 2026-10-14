# ADR-0004 — Nommage des dépôts et RBAC du registry

- **Statut** : proposé (à accepter par vous)
- **Exigences liées** : REG-01 (nommage), REG-02 (RBAC) ; ACC-01 à ACC-04 et ACC-07
- **Spec** : `nexus-spec.md` §3.1 (matrice des dépôts), §3.2 (blob stores), §4 (identifiant et chemins), §5.1 (rôles)

## Contexte

Le lot 1 démarre avec un pilote, Achera (`service.hra`), géré à la main. Il faut fixer maintenant la structure des dépôts et les rôles, car ils conditionnent les droits, les chemins et les sélecteurs de contenu. Les règles de nomenclature complètes viendront plus tard.

## Décision

### Nommage des dépôts

- Un dépôt par format et par cycle de vie : `<format>-candidat`, `<format>-release` (exemple : `maven-candidat`, `maven-release`). Les noms sont en minuscules, sans suffixe de version.
- Un blob store par dépôt, avec quota souple.
- Les dépôts proxy portent le préfixe `proxy-` (exemple : `maven-proxy-central`).
- Le format exact d'Achera (Maven, Docker, raw) détermine les dépôts créés. Le lot 1 ne crée que les dépôts de ce format.

### Nommage des chemins

- L'identifiant `service.hra` est en tête du chemin de chaque artefact (Maven : `service/hra/…` ou groupId `service.hra.*` selon le format ; Docker : premier segment `service.hra/<image>`).
- Un sélecteur de contenu limite chaque application à son préfixe.

### Rôles (RBAC)

| Rôle | Périmètre | Droits |
|---|---|---|
| `lecteur-service.hra` | Dépôts release de `service.hra` | Lecture |
| `editeur-service.hra` | Dépôt candidat de `service.hra` | Lecture et publication en candidat |
| `promotion` | Compte de la chaîne de promotion | Promotion candidat vers release |
| `mutualise-editeur` | Images dorées | Publication (équipe qui construit les images) |
| `ssi-controle` | Transverse | Lecture, gestion des quarantaines et exceptions |
| `exploitation` | Administration technique | Administration, sans publication |

Règles :
- Moindre privilège : un compte n'a que les rôles de sa matrice (ACC-03).
- Séparation : `editeur-service.hra` ne promeut pas ; `promotion` ne publie pas (ACC-04).
- Comptes techniques : le compte de déploiement a le rôle `lecteur-service.hra` seulement (ACC-07).
- Comptes locaux au lot 1, groupes d'annuaire à mapper plus tard.

## Alternatives écartées

- **Un dépôt par application** : multiplie les dépôts (environ 60 applications dans la spec) et complique la promotion.
- **Un rôle global « développeur »** : ne respecte ni le moindre privilège ni la séparation des tâches.
- **Versionner le nom du dépôt** (`maven-candidat-2`) : contraire à REG-01 et à la règle de la spec §3.1.

## Points à confirmer

- **Format d'Achera** : sans lui, les dépôts et l'exemple Docker/Maven ne sont pas définitifs.
- **Dépôts proxy** : à créer au lot 1 ou plus tard ?
- **Membres des rôles** : qui détient `ssi-controle` et `exploitation` ?

## Conséquences

- Le nom des dépôts et les rôles sont figés pour le lot 1 ; un changement demande un nouvel ADR.
- Les règles de nomenclature complètes (identifiants, noms d'images) viendront dans un ADR ultérieur.
