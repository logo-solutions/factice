# Flux de travail Git : trunk-based development

factice applique le *trunk-based development* : une seule branche longue, `main` (le tronc), toujours livrable. Ce document fixe les règles ; le pipeline qui les met en œuvre est décrit dans [flux-cicd.md](flux-cicd.md).

## Principes

| Règle | Application |
|---|---|
| Une seule branche longue | `main`. Pas de `develop`, pas de branche de release |
| Branches courtes | Une branche par changement, d'une durée de vie de quelques heures à deux jours au plus |
| Intégration continue | Chaque changement est rebasé sur `main` et fusionné au plus tôt, en petites unités |
| `main` toujours livrable | Un commit sur `main` est un candidat à la livraison : les tests passent ou il n'est pas fusionné |
| Pas de branche par environnement | Les environnements (intégration, production) se distinguent par le déploiement, pas par la branche |
| Livraison par promotion | On ne reconstruit pas pour la production : on promeut l'artefact déjà construit et contrôlé |

## Cycle d'un changement

1. Créer une branche courte depuis `main` (`feat/…`, `fix/…`, `docs/…`).
2. Pousser : le workflow exécute les tests et la construction (étape `build`), sans rien publier dans Nexus.
3. Ouvrir une demande de fusion : les tests doivent passer, la fusion se fait par *squash* ou par rebase.
4. À la fusion sur `main`, le pipeline publie le candidat, le promeut en release et le déploie en intégration.
5. La production se déclenche à la main, sur une release déjà promue (voir ci-dessous).

## Protection de `main`

Réglages attendus sur GitHub :

- fusion uniquement par demande de fusion, avec le contrôle `build` obligatoire ;
- pas de poussée directe, pas de poussée forcée ;
- historique linéaire.

Ces réglages ne sont pas de la décoration : le contrôle de provenance de la promotion (`scripts/nexus/promote.sh`) refuse toute image dont le commit n'appartient pas à `origin/main`.

## Ce qui remplace les branches de release

Dans un modèle à branches (`develop`, `release/x.y`), l'état d'un environnement se lit dans la branche. Ici il se lit dans Nexus :

| Besoin | Réponse trunk-based |
|---|---|
| Savoir ce qui est candidat | Image dans `docker-candidat` |
| Savoir ce qui est livrable | Image dans `docker-release` (immuable, sans étiquette `latest`) |
| Savoir ce qui tourne en production | Empreinte de l'image déployée, tracée par l'événement de déploiement |
| Retour arrière | Redéployer l'empreinte de la release précédente |
| Correctif urgent | Un changement court sur `main`, promu comme les autres (pas de branche de correctif) |

## Fonctionnalités inachevées

Un changement non terminé ne reste pas sur une branche : il est fusionné derrière un interrupteur de fonctionnalité (variable de configuration), désactivé par défaut. Cela évite les branches longues et les conflits de fusion.

## Décision associée

Voir [decisions.md](decisions.md), décision 13.
