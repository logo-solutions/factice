# Exigences

Référentiel vivant des exigences que l'on pose aux éditeurs (COTS, SaaS, low code) et aux solutions que l'on intègre à la chaîne de livraison.

Ce dossier répond à trois questions : **pourquoi** on exige (contexte et enjeux), **quoi** (les exigences), **comment on s'assure** que l'éditeur les respecte (la preuve attendue).

## Organisation

| Fichier | Contenu |
|---|---|
| [00-contexte-enjeux.md](00-contexte-enjeux.md) | Contexte, enjeux, périmètre, acteurs, hypothèses. À lire d'abord |
| [10-controle-acces-segregation.md](10-controle-acces-segregation.md) | Domaine ACC : ségrégation logique, rôles, authentification, comptes techniques, traçabilité des accès |
| `NN-<domaine>.md` | Un fichier par domaine (voir la liste ci-dessous) |
| [organisation.md](organisation.md) | Règle dépôt / wiki, contrôles du pipeline, ce qui est auditable |
| [modeles/](modeles/) | Gabarit d'exigence, page de consultation (wiki), fichier de réponse d'éditeur |
| [journal.md](journal.md) | Historique des décisions et des changements du référentiel |

## Domaines

| Code | Domaine | Fichier | État |
|---|---|---|---|
| ACC | Contrôle d'accès et ségrégation logique | [10-controle-acces-segregation.md](10-controle-acces-segregation.md) | Premier jet |
| SBOM | Transparence de la chaîne logicielle (SBOM, vulnérabilités) | à créer | À rédiger. Voir `1-fondations/flux-outils.md`, décision 3 |
| TRC | Traçabilité et journalisation | à créer | À rédiger |
| CRY | Chiffrement et gestion des secrets | à créer | À rédiger |
| INT | Intégration et automatisation (API, déploiement) | à créer | À rédiger |
| EXP | Exploitation, sauvegarde, supervision | à créer | À rédiger |
| REV | Réversibilité et sortie de contrat | à créer | À rédiger |
| CTR | Support, engagements de service, licences | à créer | À rédiger |

Un domaine est créé quand on a au moins trois exigences à y mettre. Avant cela, les idées vont dans la section « À instruire » du fichier du domaine le plus proche.

## Anatomie d'une exigence

Chaque exigence est un bloc court, avec les mêmes champs partout (voir [modeles/gabarit-exigence.md](modeles/gabarit-exigence.md)) :

| Champ | Rôle |
|---|---|
| **Identifiant** | `ACC-03` : code du domaine plus numéro. Stable, jamais réutilisé, même si l'exigence disparaît |
| **Énoncé** | Une phrase, une seule exigence, vérifiable. Formulé avec DOIT / DEVRAIT / PEUT |
| **Pourquoi** | Le risque ou l'enjeu couvert. Sans lui, l'exigence devient arbitraire et se négocie mal |
| **Preuve attendue** | Ce que l'éditeur fournit pour démontrer qu'il la respecte |
| **Applicabilité** | À quels types de solution elle s'applique (COTS, SaaS, low code) |
| **Source** | Norme, guide ou décision d'où elle vient |
| **Version** | `1.0`, `1.1`, `2.0`… Chaque exigence est versionnée individuellement (voir [Versionnement](#versionnement)) |
| **Statut** | Cycle de vie (voir ci-dessous) |

### Verbes (convention RFC 2119)

| Verbe | Sens | Effet dans un appel d'offres |
|---|---|---|
| **DOIT** | Obligatoire | Critère éliminatoire |
| **DEVRAIT** | Fortement recommandé | Noté. Un écart doit être justifié |
| **PEUT** | Optionnel | Bonus |

### Preuves (colonne « Preuve attendue »)

| Code | Preuve | Force |
|---|---|---|
| **DOC** | Documentation de l'éditeur | Faible : déclarative |
| **ATT** | Attestation ou certification de tiers (ISO 27001, SOC 2…) | Moyenne |
| **DEM** | Démonstration sur notre environnement | Forte |
| **TST** | Test que nous exécutons nous-mêmes | Forte, et rejouable |
| **CTR** | Engagement contractuel avec pénalité | Complète une autre preuve |

Une exigence DOIT dont la seule preuve est DOC est fragile : on le signale dans le champ « Réserve ».

### Statuts

`brouillon` → `à valider` → `validée` → `diffusée` (envoyée aux éditeurs) → `obsolète`

Une exigence obsolète n'est jamais supprimée : elle garde son identifiant et indique ce qui la remplace.

## Versionnement

Une exigence évolue (norme mise à jour, retour d'un éditeur, nouvelle menace). Or une consultation ou un contrat se réfèrent à **un état précis** de l'exigence. Chaque exigence porte donc sa propre version, indépendante des autres.

| Version | Quand | Exemple |
|---|---|---|
| `0.x` | Tant que l'exigence est `brouillon` ou `à valider` | `0.1`, `0.2` |
| `1.0` | À la première validation (statut `validée`) | `1.0` |
| `N.M` mineure (`1.0` → `1.1`) | Reformulation, précision, correction de source, **sans changer ce qu'on exige** | clarifier un terme |
| `N+1.0` majeure (`1.1` → `2.0`) | Changement de ce qu'on exige : priorité (DEVRAIT → DOIT), périmètre, critère d'acceptation, preuve attendue | ajouter une preuve de type test |

Règles :

1. **Citer l'identifiant avec sa version** dans les consultations, les réponses d'éditeurs, les contrats et les demandes de fusion : `ACC-01 v1.0`. Sans version, on ne sait pas à quoi l'éditeur a répondu.
2. **Le statut `diffusée` est attaché à une version.** Une exigence passée en `2.0` repasse à `à valider`. La `1.0` reste `diffusée` pour les consultations déjà envoyées.
3. **Une majeure se signale** : on liste les consultations ou réponses qui référencent l'ancienne version et qu'il faut éventuellement rejouer.
4. **Le texte d'une version diffusée n'est jamais réécrit**. On passe à la version suivante, et le Git (étiquette ou commit) conserve l'ancien énoncé.
5. **Chaque changement de version est tracé** dans [journal.md](journal.md) : identifiant, ancienne et nouvelle version, ce qui change, pourquoi.
6. Une exigence `obsolète` garde sa dernière version et indique ce qui la remplace.

## Comment faire vivre le document

1. Une exigence naît dans la section « À instruire » du domaine, avec juste un titre et le pourquoi.
2. On la rédige avec le gabarit, statut `brouillon`.
3. Elle passe à `à valider` quand l'énoncé et la preuve attendue sont écrits.
4. Chaque changement de fond change la version de l'exigence et est noté dans [journal.md](journal.md) : date, identifiant, versions, ce qui a changé, pourquoi.
5. Les modifications passent par une demande de fusion. Le Git garde l'historique, `git blame` donne l'auteur.

## Utilisation

- **Consultation (RFI, RFP, RFQ)** : on extrait les exigences `validée` d'un domaine, avec leur priorité et leur preuve attendue, et on crée la page de consultation dans le wiki.
- **Réponse de l'éditeur** : un fichier par éditeur, par exigence : conforme, partiel ou non conforme, avec le lien vers la preuve.
- **Traçabilité** : les identifiants avec leur version (`ACC-03 v1.0`) sont ceux que l'on cite dans les commits, les demandes de fusion et les contrats (flux 1 de `1-fondations/flux-outils.md`).
- **Où vit quoi, et comment c'est contrôlé** : voir [organisation.md](organisation.md).

## Références

- Sources et normes consultées : voir le champ « Source » de chaque exigence. Les numéros de contrôle sont indicatifs, à confirmer sur la version en vigueur avant diffusion.
