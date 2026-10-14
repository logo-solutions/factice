# ACC — Contrôle d'accès et ségrégation logique

Premier jet à challenger. Toutes les exigences sont en version `0.1`, statut `brouillon`. Règles de versionnement : voir le [README](README.md#versionnement).

## Enjeu du domaine

Une solution doit permettre de **cloisonner** les données et les actions par périmètre (équipe, projet, environnement), d'attribuer des droits **précis et revoyables** à des rôles, et de **prouver** après coup qui a fait quoi. Sans cela, on ne peut ni limiter l'impact d'une erreur ou d'une compromission, ni passer un audit.

## Vue d'ensemble

| ID | Titre | Version | Priorité | Preuve principale |
|---|---|---|---|---|
| ACC-01 | Ségrégation logique par périmètre | 0.1 | DOIT | DEM |
| ACC-02 | Contrôle d'accès par rôles | 0.1 | DOIT | DEM |
| ACC-03 | Moindre privilège par défaut | 0.1 | DOIT | TST |
| ACC-04 | Séparation des tâches | 0.1 | DOIT | DEM |
| ACC-05 | Authentification déléguée et MFA | 0.1 | DOIT | DEM |
| ACC-06 | Provisionnement automatisé des accès | 0.1 | DEVRAIT | DEM |
| ACC-07 | Comptes techniques maîtrisés | 0.1 | DOIT | DEM |
| ACC-08 | Journal des accès et des changements de droits | 0.1 | DOIT | DEM |
| ACC-09 | Export des droits pour revue | 0.1 | DEVRAIT | TST |
| ACC-10 | Accès du personnel de l'éditeur | 0.1 | DOIT | CTR |
| ACC-11 | Isolation entre clients de l'éditeur | 0.1 | DOIT | ATT |

## Exigences

### ACC-01 — Ségrégation logique par périmètre

**Énoncé.** La solution DOIT permettre de cloisonner données, configurations et actions par périmètre (par exemple équipe, projet, environnement), sans accès croisé par défaut entre périmètres.

**Pourquoi.** Limiter l'impact d'une erreur ou d'un compte compromis à un seul périmètre, et séparer les environnements (intégration, production).

| | |
|---|---|
| Priorité | DOIT |
| Applicabilité | COTS, SaaS, low code |
| Preuve attendue | DEM : deux périmètres créés, un utilisateur du premier ne voit ni ne modifie rien du second (interface et API) |
| Critère d'acceptation | Aucune donnée du périmètre B visible depuis A, y compris par la recherche et l'API |
| Réserve | Une simple documentation (DOC) ne suffit pas : l'API et la recherche sont des fuites classiques |
| Source | ISO 27001:2022 A.5.15, A.8.3 ; OWASP ASVS (contrôle d'accès) |
| Version | 0.1 |
| Statut | brouillon |

### ACC-02 — Contrôle d'accès par rôles

**Énoncé.** La solution DOIT attribuer les droits via des rôles, avec des permissions distinctes pour la lecture, l'écriture, l'approbation et l'administration, et DOIT permettre de définir des rôles personnalisés.

**Pourquoi.** Des droits attribués à des rôles, pas à des personnes, se gèrent, se revoient et se transfèrent.

| | |
|---|---|
| Priorité | DOIT |
| Applicabilité | COTS, SaaS, low code |
| Preuve attendue | DEM : création d'un rôle personnalisé, assignation, effet vérifié |
| Critère d'acceptation | Un rôle peut être limité à un périmètre et à un sous-ensemble d'actions |
| Source | ISO 27001:2022 A.5.15, A.5.18 |
| Version | 0.1 |
| Statut | brouillon |

### ACC-03 — Moindre privilège par défaut

**Énoncé.** La solution DOIT n'accorder aucun droit à un nouvel utilisateur ou à un nouveau groupe sans attribution explicite, et son rôle par défaut DOIT être le plus restreint.

**Pourquoi.** Un droit oublié vaut mieux absent qu'accordé : l'excès de droits est la dérive la plus fréquente.

| | |
|---|---|
| Priorité | DOIT |
| Applicabilité | COTS, SaaS, low code |
| Preuve attendue | TST : on crée un utilisateur sans rôle et on tente un accès |
| Critère d'acceptation | Accès refusé partout, hors les pages strictement nécessaires à la connexion |
| Source | ISO 27001:2022 A.8.2 ; ANSSI (principe du moindre privilège) |
| Version | 0.1 |
| Statut | brouillon |

### ACC-04 — Séparation des tâches

**Énoncé.** La solution DOIT permettre qu'une action sensible (approbation, déploiement, modification des droits) ne puisse pas être demandée et approuvée par la même personne.

**Pourquoi.** C'est le fondement de l'approbation de la production décrite dans `1-fondations/flux-outils.md` : le contrôle ne vaut que si l'approbateur est distinct de l'auteur.

| | |
|---|---|
| Priorité | DOIT |
| Applicabilité | COTS, SaaS, low code |
| Preuve attendue | DEM : tentative d'auto-approbation, refusée par la solution |
| Critère d'acceptation | L'auto-approbation est impossible, ou configurable en interdit, sans contournement par un rôle administrateur ordinaire |
| Source | ISO 27001:2022 A.5.3 |
| Version | 0.1 |
| Statut | brouillon |

### ACC-05 — Authentification déléguée et MFA

**Énoncé.** La solution DOIT déléguer l'authentification à un fournisseur d'identité externe via OIDC ou SAML, et DOIT imposer ou accepter l'authentification multifacteur pour les comptes à privilèges.

**Pourquoi.** Une seule identité par personne, gérée en un point : révocation immédiate au départ, pas de mots de passe supplémentaires à protéger.

| | |
|---|---|
| Priorité | DOIT |
| Applicabilité | COTS, SaaS, low code |
| Preuve attendue | DEM : connexion via notre fournisseur d'identité, MFA exigé sur un rôle d'administration |
| Critère d'acceptation | Désactiver un compte chez le fournisseur d'identité coupe l'accès à la solution |
| Source | ISO 27001:2022 A.5.16, A.8.5 ; OWASP ASVS (authentification) |
| Version | 0.1 |
| Statut | brouillon |

### ACC-06 — Provisionnement automatisé des accès

**Énoncé.** La solution DEVRAIT permettre de créer, modifier et retirer des comptes et des appartenances à des groupes par API ou par un standard (SCIM), et d'associer les groupes du fournisseur d'identité à des rôles.

**Pourquoi.** Éviter les comptes orphelins et la saisie manuelle des droits.

| | |
|---|---|
| Priorité | DEVRAIT |
| Applicabilité | COTS, SaaS |
| Preuve attendue | DEM : ajout d'un utilisateur à un groupe, rôle obtenu sans intervention manuelle |
| Critère d'acceptation | Retrait du groupe = retrait du rôle, dans un délai défini **[à fixer]** |
| Source | ISO 27001:2022 A.5.16, A.5.18 |
| Version | 0.1 |
| Statut | brouillon |

### ACC-07 — Comptes techniques maîtrisés

**Énoncé.** La solution DOIT distinguer les comptes de service des comptes humains, et DOIT permettre pour eux des jetons à portée limitée, à durée de vie bornée, révocables individuellement et renouvelables sans interruption.

**Pourquoi.** Les automatismes (pipeline, déploiement) tournent avec des comptes techniques : un jeton à tous droits et sans expiration est un risque majeur. Cela rejoint les trois comptes cloisonnés du registry décrits dans `1-fondations/flux-et-reseau.md`.

| | |
|---|---|
| Priorité | DOIT |
| Applicabilité | COTS, SaaS, low code |
| Preuve attendue | DEM : création d'un jeton limité à un périmètre et à la lecture, expiration, révocation |
| Critère d'acceptation | Un jeton ne dépasse jamais les droits du compte qui le porte |
| Source | ISO 27001:2022 A.5.17, A.8.2 ; OWASP ASVS |
| Version | 0.1 |
| Statut | brouillon |

### ACC-08 — Journal des accès et des changements de droits

**Énoncé.** La solution DOIT journaliser les connexions, les accès refusés, les actions sensibles et tout changement de rôle ou de droit, avec auteur, date et objet, et DOIT permettre l'export du journal vers un système tiers (API ou flux standard).

**Pourquoi.** Sans journal exportable, on ne peut ni enquêter après un incident ni démontrer la conformité.

| | |
|---|---|
| Priorité | DOIT |
| Applicabilité | COTS, SaaS, low code |
| Preuve attendue | DEM : actions réalisées, retrouvées dans le journal exporté |
| Critère d'acceptation | Journal non modifiable par un administrateur de la solution ; durée de conservation précisée |
| Source | ISO 27001:2022 A.8.15 ; ANSSI (journalisation) |
| Version | 0.1 |
| Statut | brouillon |

### ACC-09 — Export des droits pour revue

**Énoncé.** La solution DEVRAIT permettre d'exporter, de façon exploitable par une machine, la matrice des utilisateurs, des rôles et des périmètres.

**Pourquoi.** Permet les revues périodiques de droits et la détection des écarts, sans comptage manuel.

| | |
|---|---|
| Priorité | DEVRAIT |
| Applicabilité | COTS, SaaS, low code |
| Preuve attendue | TST : export réalisé et rapproché de l'attendu |
| Critère d'acceptation | Export complet, daté, au format ouvert (CSV, JSON) |
| Source | ISO 27001:2022 A.5.18 |
| Version | 0.1 |
| Statut | brouillon |

### ACC-10 — Accès du personnel de l'éditeur

**Énoncé.** L'éditeur DOIT s'engager à n'accéder à nos données ou à notre instance qu'avec notre autorisation préalable, pour une durée limitée, et avec une trace consultable de chaque accès.

**Pourquoi.** Le support de l'éditeur est un accès privilégié que nous ne contrôlons pas directement.

| | |
|---|---|
| Priorité | DOIT |
| Applicabilité | SaaS, COTS avec support à distance |
| Preuve attendue | CTR : clause contractuelle ; DOC : procédure d'accès support |
| Critère d'acceptation | Accès support impossible sans action de notre part, ou signalé et tracé |
| Réserve | Engagement contractuel et déclaratif, difficile à tester |
| Source | ISO 27001:2022 A.5.19 à A.5.22 (relations avec les fournisseurs) |
| Version | 0.1 |
| Statut | brouillon |

### ACC-11 — Isolation entre clients de l'éditeur

**Énoncé.** Pour une solution multi-clients, l'éditeur DOIT garantir l'isolation des données entre clients et DOIT documenter le mécanisme (instances séparées, schémas séparés, cloisonnement applicatif).

**Pourquoi.** Dans un SaaS, la ségrégation entre clients de l'éditeur est hors de notre contrôle : on s'appuie sur l'engagement et les preuves de tiers.

| | |
|---|---|
| Priorité | DOIT |
| Applicabilité | SaaS |
| Preuve attendue | ATT : certification ou rapport d'audit indépendant couvrant l'isolation ; DOC : architecture |
| Critère d'acceptation | Rapport d'audit récent, couvrant le périmètre du service souscrit |
| Réserve | Pas de test possible de notre côté |
| Source | ISO 27001:2022 A.5.23 (services cloud) ; ISO 27017 |
| Version | 0.1 |
| Statut | brouillon |

## À instruire

- Gestion des **sessions** : durée, verrouillage, déconnexion forcée.
- **Accès d'urgence** (« bris de glace ») : comptes de secours, contrôle et trace.
- **Délégation temporaire** de droits, avec expiration.
- Contrôle d'accès **au niveau de l'objet** (fiche, document) et pas seulement de la page.
- **Revue périodique** des droits : qui la fait, à quelle fréquence, avec quels exports.
