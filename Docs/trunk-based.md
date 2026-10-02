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

## Merge Request (Pull Request)

Une **Merge Request (MR)** est une demande de révision et d'approbation avant de fusionner une branche avec `main`. C'est le mécanisme de contrôle de qualité du trunk-based development.

### Workflow d'une Merge Request

1. **Création** : Après le premier push d'une branche, ouvrir une MR sur GitHub.
   - Titre : Décrire le changement (ex: `feat: ajouter route GET /health`)
   - Description : Pourquoi ? Quoi ? Comment tester ?
   - Labelliser (ex: `type:feature`, `priority:high`)

2. **Automatisation (CI/CD)** : À l'ouverture et à chaque push, le workflow `.github/workflows/ci.yml` :
   - Exécute tests (`npm run test`)
   - Lint du code (`npm run lint`)
   - Type-check (`npm run type-check`)
   - Build artefact (sans publication Nexus)
   - Affiche le statut ✅ ou ❌ sur la MR

3. **Révision par les pairs** :
   - Minimum 1 reviewer approuvé
   - Commentaires sur les lignes, questions, suggestions
   - Auteur répond et applique les changements
   - Reviewer approuve une fois satisfait

4. **Résolution des conflits** : Si `main` a avancé :
   - Rebase la branche sur `main` (garder historique linéaire)
   - Résoudre les conflits localement
   - Re-push : CI relance automatiquement

5. **Fusion** :
   - Stratégie : **Squash and merge** (par défaut) ou **Rebase and merge**
   - Squash : tous les commits deviennent 1 commit sur `main`
   - Rebase : tous les commits gardés, juste rembobinés sur `main`
   - Choix : Squash pour les petits changements, Rebase pour garder l'historique
   - Branche supprimée automatiquement après merge

### Checklist avant de merger

- [ ] CI/CD pipeline ✅ (tests, lint, build)
- [ ] Minimum 1 approval
- [ ] Pas de conflits avec `main`
- [ ] Commit message clair et aux normes Conventional Commits
- [ ] Modifications limitées (< 400 lignes idéalement)
- [ ] SBOM généré si nouvelle dépendance
- [ ] Docs mises à jour si changement API

### Durée de vie typique d'une MR

| Étape | Durée |
|---|---|
| Création → Première review | 2-4 heures |
| Feedback → Corrections | 1-4 heures |
| Approval → Merge | < 1 heure |
| **Total** | **4-10 heures** (idéalement < 1 jour) |

**Objectif SLO** : 90 % des MRs mergées en < 24 heures.

### Permissions de merge

| Rôle | Peut merger |
|---|---|
| Mainteneurs du repo | ✅ Toujours |
| Contributeurs réguliers | ✅ Leur propre MR (après approval) |
| Contributeurs externes | ❌ Attendre approval mainteneur |

### Distinction : Trunk-based vs Merge Request

| Aspect | Trunk-based | Merge Request |
|---|---|---|
| **Définition** | Stratégie de branching (1 branche longue) | Mécanisme de révision avant merge |
| **Objectif** | Déploiement continu, main toujours stable | Assurance qualité, traçabilité |
| **Obligatoire ?** | Oui (1 seule branche longue) | Oui (protection de main) |
| **Durée** | Branches courtes (heures à 2 jours) | MRs courtes (heures à 1 jour) |
| **Relation** | Trunk-based **utilise** les MRs comme point de contrôle | Les MRs implémentent la stabilité de trunk-based |

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
