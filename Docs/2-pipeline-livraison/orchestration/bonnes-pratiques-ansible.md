# Bonnes pratiques Ansible

Ce document confronte les rôles et playbooks de factice aux pratiques de référence pour une automatisation Ansible de production. Chaque section donne le **principe**, l'**état actuel** et la **cible**. Rien de ce qui est décrit en « cible » n'est encore appliqué au code.

Contexte d'exécution : [workflow-ansible.md](workflow-ansible.md). Rôle générique : [compose-deploy-contract.md](compose-deploy-contract.md).

## Synthèse

| Domaine | État actuel | Écart |
|---|---|---|
| Analyse statique (`ansible-lint`, `yamllint`) | aucun fichier de configuration, aucune exécution en CI | à mettre en place |
| Noms de modules qualifiés (FQCN) | partiellement (`community.docker.docker_compose_v2`), le reste non | à généraliser |
| Validation des arguments des rôles | aucune `argument_specs` | à ajouter |
| Tests (Molecule) | aucun scénario | partiellement impossible sur macOS natif |
| Simulation avant déploiement (`--check --diff`) | non exécutée | à ajouter |
| Secrets | `vault.yml` en clair, valeurs `changeme-*` | à chiffrer ou externaliser |
| Gestion des erreurs | plusieurs `ignore_errors: true` | à remplacer |
| Idempotence | conçue, non vérifiée automatiquement | à vérifier |
| Détection de dérive | aucune | à planifier |
| Déploiement et retour arrière | séquentiel, contrôle de santé, retour arrière manuel | à compléter |

## 1. Analyse statique

**Principe.** Un défaut de style ou d'usage se détecte avant l'exécution. `ansible-lint` applique des règles par profils de rigueur croissante (`min`, `basic`, `moderate`, `safety`, `shared`, `production`) ; le profil `production` est le plus strict et vise les contenus déployés en production. `yamllint` vérifie la syntaxe et le style YAML.

**Cible.**

- un fichier `.ansible-lint` fixant `profile: production` ;
- un fichier `.yamllint` ;
- une étape d'intégration continue qui lance `ansible-lint` et `ansible-playbook --syntax-check` sur chaque demande de fusion ;
- adoption progressive : relever d'abord les écarts existants, puis les traiter ou les lister dans la configuration avec justification.

## 2. Noms de modules qualifiés

**Principe.** Écrire `ansible.builtin.template` plutôt que `template`. Un nom complet lève toute ambiguïté si une collection fournit un module du même nom, et le profil `production` l'exige.

**État.** `compose_deploy` utilise des noms complets (`ansible.builtin`) ; dans `roles/factice`, `template`, `shell`, `uri`, `pause` sont encore écrits sans collection.

**Cible.** Qualifier tous les modules ; déclarer les collections nécessaires dans un `requirements.yml` versionné, avec leur version.

## 3. Validation des arguments des rôles

**Principe.** `meta/argument_specs.yml` décrit les variables d'un rôle : type, défaut, caractère obligatoire, valeurs autorisées. Ansible valide les arguments au début du rôle et échoue avec un message clair. C'est la forme exécutable du contrat documenté dans [compose-deploy-contract.md](compose-deploy-contract.md).

**État.** Les contrats sont décrits en prose ; aucune validation.

**Cible.** Un fichier `argument_specs.yml` pour `factice` (celui de `compose_deploy` existe depuis le 2026-10-09), avec en particulier `factice_environment` limité à `integration` et `production`, et `factice_release_image` obligatoire pour les déploiements.

## 4. Tests de rôles

**Principe.** Molecule enchaîne la création d'une cible jetable, l'application du rôle (*converge*), une seconde application dont on attend `changed=0` (*idempotence*) puis des vérifications (*verify*).

**Limite propre à factice.** Les tiers BDD et Web sont natifs macOS (Homebrew, `launchctl`) : ils ne peuvent pas s'exécuter dans un conteneur Linux, qui est la cible habituelle de Molecule. Il y a donc trois niveaux de test.

| Niveau | Cible | Couvre |
|---|---|---|
| Syntaxe et analyse | n'importe où | tous les rôles |
| Molecule, conteneur Linux | `compose_deploy` (scénario dans maisonnettev2) | création de la pile, santé, idempotence (la pile est un conteneur) |
| Exécution réelle sur l'hôte macOS, en intégration | l'hôte | tiers natifs : le second passage doit rendre `changed=0` |

**Cible.** Le scénario Molecule de `compose_deploy` existe (dans maisonnettev2) ; reste un contrôle d'idempotence systématique sur l'environnement d'intégration (le workflow lance le playbook deux fois, le second doit rapporter `changed=0`).

## 5. Simulation avant déploiement

**Principe.** `ansible-playbook --check --diff` montre ce qui changerait sans le faire. Utile avant la production et pour détecter une dérive.

**Cible.**

- une simulation du playbook de production avant le déploiement, avec la différence affichée dans le journal du job ;
- une simulation **planifiée** sur chaque environnement : toute tâche qui rapporterait `changed` sur un environnement qu'on croit stable indique une **dérive** (modification manuelle, service arrêté), à signaler.

**Réserve.** Certaines tâches (`shell`, `command`) ne se simulent pas fidèlement ; les remplacer par des modules dédiés rend la simulation fiable.

## 6. Gestion des secrets

**Principe.** Un secret ne doit ni apparaître en clair dans le dépôt, ni dans un journal. Deux approches :

| Approche | Avantage | Contrainte |
|---|---|---|
| Ansible Vault (fichier chiffré versionné) | simple, aucune dépendance externe | gestion de la clé de déverrouillage, rotation manuelle, un fichier chiffré se compare mal en revue |
| Gestionnaire externe lu à l'exécution (par exemple Bitwarden Secrets Manager via un *lookup*) | rotation et audit centralisés, aucune valeur dans le dépôt | dépendance disponible au moment du déploiement |

**État.** Le fichier `vault.yml` est versionné **en clair** avec des valeurs `changeme-*` ; la clé `~/.factice-vault-pass` est lue par le workflow. Le `no_log: true` n'est posé que sur une tâche (`tier_app.yml`).

**Cible.**

- chiffrer `vault.yml` ou le remplacer par un gestionnaire externe ; ne jamais déposer de valeur réelle tant que ce n'est pas fait ;
- un identifiant de coffre et une clé par environnement, pour qu'une compromission de l'intégration n'ouvre pas la production ;
- `no_log: true` sur toute tâche qui reçoit ou affiche un secret ;
- une rotation datée de chaque secret.

## 7. Gestion des erreurs

**Principe.** `ignore_errors: true` masque aussi les vraies pannes. Préférer :

- `failed_when` avec une condition précise sur la sortie ;
- `block` / `rescue` / `always` pour une action de récupération explicite ;
- des modules idempotents plutôt que `shell` + code de retour.

**État.** `ignore_errors: true` figure dans les gestionnaires de `factice` et dans le tier BDD.

**Cible.** Les remplacer un à un, en listant pour chacun le cas d'erreur réellement attendu.

## 8. Idempotence

**Principe.** Deux passages successifs sur un hôte inchangé rendent `changed=0`. C'est la base d'un déploiement rejouable et d'une simulation fiable.

**Points d'attention dans factice.**

- les gabarits identiques ne changent rien : bon ;
- `shell: docker system prune` est toujours `changed` : à remplacer par `community.docker.docker_prune` ;
- `recreate_containers: true` en production recrée toujours les conteneurs : c'est un choix volontaire, mais il rend le second passage non nul sur cet environnement ; l'indiquer dans le contrôle d'idempotence.

## 9. Déploiement sur un hôte unique

Un seul hôte porte l'application : on ne peut pas faire de déploiement progressif entre machines. Trois stratégies sont possibles, par complexité croissante.

| Stratégie | Principe | Avantage | Limite |
|---|---|---|---|
| **Séquentielle avec contrôle de santé** (actuelle) | remplacer le conteneur, vérifier `/health` | simple | brève coupure ; en cas d'échec, retour arrière manuel |
| **Séquentielle avec retour arrière automatique** | si le contrôle de santé échoue, relancer avec l'empreinte précédente | rétablit le service sans intervention | exige de mémoriser l'empreinte précédente |
| **Bleu/vert derrière Caddy** | démarrer la nouvelle version sur un second port, basculer le proxy après contrôle, arrêter l'ancienne | pas de coupure, retour instantané | double consommation de ressources, ports à gérer par environnement |

**Contrôles de santé.** Distinguer deux questions : *vivacité* (le processus tourne) et *disponibilité* (il peut servir, base de données comprise). L'instruction `HEALTHCHECK` de l'image porte la première ; `/health` interrogé à travers le proxy valide la seconde de bout en bout, comme le fait déjà la chaîne de validation.

**Base de données.** Le retour arrière d'une image ne défait pas une migration. Pour qu'une ancienne image reste compatible avec la base, appliquer le schéma *expand / contract* : une release **ajoute** (colonnes ou tables optionnelles), la suivante **bascule** l'usage, une troisième **supprime** l'ancien.

## 10. Plan d'adoption suggéré

| Ordre | Mesure | Effort |
|---|---|---|
| 1 | Chiffrer ou externaliser les secrets du coffre | faible |
| 2 | `.ansible-lint` (profil `production`), `.yamllint`, `--syntax-check` en CI | faible |
| 3 | Qualifier les modules, retirer les `ignore_errors` | moyen |
| 4 | `argument_specs.yml` pour `factice` (fait pour `compose_deploy`) | moyen |
| 5 | Contrôle d'idempotence (double passage) en intégration | faible |
| 6 | Simulation `--check --diff` avant la production, puis planifiée | moyen |
| 7 | Scénario Molecule pour `compose_deploy` : fait (dans maisonnettev2) | — |
| 8 | Retour arrière automatique sur échec de santé | moyen |

## Références

- Ansible, [Good practices for variables and vaults](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html), [validation des arguments de rôle](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html#role-argument-validation), [Ansible Vault](https://docs.ansible.com/ansible/latest/vault_guide/index.html)
- [ansible-lint, profils](https://ansible.readthedocs.io/projects/lint/profiles/)
- [Molecule](https://ansible.readthedocs.io/projects/molecule/)
- NIST, [SP 800-204D](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-204D.pdf) (intégrité de la chaîne de livraison)
