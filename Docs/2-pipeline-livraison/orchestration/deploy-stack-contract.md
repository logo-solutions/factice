# Contrat d'appel de `roles/deploy_stack`

## Objectif

`deploy_stack` est un rôle Ansible générique qui factorise le squelette de déploiement d'une pile Docker Compose. Il :

1. crée le répertoire de la pile ;
2. crée le réseau Docker s'il n'existe pas ;
3. lance la pile avec `community.docker.docker_compose_v2` ;
4. attend les contrôles de santé (URL, puis état des conteneurs) ;
5. affiche le résultat.

Le rôle ne rend aucun gabarit : l'appelant produit `docker-compose.yml` et `.env` dans `stack_dir` avant de l'appeler. Cela garde `deploy_stack` indépendant de l'application déployée.

## Variables

### Obligatoires

| Variable | Description |
|---|---|
| `stack_name` | nom de la pile (non vide) |
| `stack_dir` | répertoire contenant `docker-compose.yml` et `.env` |

### Optionnelles

| Variable | Défaut | Description |
|---|---|---|
| `pull_images` | `true` | `true` : politique de tirage `always` ; `false` : `never` |
| `recreate_containers` | `false` | `true` : recréation systématique des conteneurs ; sinon seulement si la configuration change |
| `prune_on_deploy` | `false` | nettoie les ressources Docker inutilisées avant le démarrage |
| `healthcheck_urls` | `[]` | URL à interroger après le démarrage |
| `healthcheck_retries` | `30` | nombre de tentatives |
| `healthcheck_delay` | `5` | pause en secondes avant les contrôles |
| `healthcheck_timeout` | `10` | délai de connexion en secondes |
| `docker_network` | `factice-network` | réseau Docker à créer |
| `docker_network_driver` | `bridge` | pilote du réseau |

### Variable d'inventaire facultative

| Variable | Rôle |
|---|---|
| `docker_host` | socket Docker (par défaut `unix:///var/run/docker.sock`) |

## Exemple d'appel

Extrait de `roles/factice/tasks/tier_app.yml` :

```yaml
- name: Template docker-compose for app tier
  template:
    src: docker-compose.app.yml.j2
    dest: "{{ tier_app_base_dir }}/docker-compose.yml"

- name: Template app environment file
  template:
    src: .env.app.j2
    dest: "{{ tier_app_base_dir }}/.env"
    mode: "0600"

- name: Use deploy_stack role for application container
  include_role:
    name: deploy_stack
  vars:
    stack_name: "{{ tier_app_container_name }}"
    stack_dir: "{{ tier_app_base_dir }}"
    pull_images: true
    recreate_containers: "{{ factice_environment == 'production' }}"
    healthcheck_urls: ["{{ tier_app_healthcheck_endpoint }}"]
```

## Secrets

Les secrets (mots de passe, jetons) sont rendus par l'appelant dans `.env` (mode `0600`), à partir de variables du coffre Ansible (`inventory/group_vars/local/vault.yml`). `deploy_stack` ne les voit pas et ne les journalise pas.

## Gestionnaires

`handlers/main.yml` expose trois gestionnaires, déclenchés par `notify` ou `listen` : `restart_stack`, `restart_service` (variable `service_to_restart`) et `reload_compose`.

## Idempotence

Un second passage sans changement de configuration ni d'image rend `changed=0`. Seuls un fichier Compose modifié, une nouvelle empreinte d'image ou `recreate_containers: true` recréent les conteneurs.

## Hors périmètre

`deploy_stack` ne gère que des conteneurs. Il ne fait pas :

- l'installation de dépendances système ;
- la création de bases de données ;
- la configuration de processus natifs ;
- la logique métier après déploiement (initialisation, données de départ).

Ces tâches restent au rôle appelant.

## Écarts et évolutions

Constats faits en relisant le rôle, à traiter pour qu'il respecte les bonnes pratiques décrites dans [bonnes-pratiques-ansible.md](bonnes-pratiques-ansible.md) :

| Constat | Risque | Cible |
|---|---|---|
| Aucune validation des arguments : les variables « obligatoires » ne sont pas déclarées dans `meta/argument_specs.yml` | une faute de frappe ou un oubli est détecté tard, par une erreur obscure | déclarer types, défauts et variables obligatoires dans `meta/argument_specs.yml` ; Ansible les valide avant la première tâche |
| La création du réseau Docker utilise `ignore_errors: true` | une vraie erreur (démon arrêté, droits) est masquée avec « le réseau existe peut-être » | retirer `ignore_errors` : le module `docker_network` est déjà idempotent et n'échoue pas si le réseau existe |
| Le nettoyage (`prune_on_deploy`) passe par `shell: docker system prune -f` | le module `shell` n'est pas idempotent et le nettoyage global peut supprimer des ressources d'autres piles | `community.docker.docker_prune`, avec filtres limités à ce qui appartient à la pile |
| Modules appelés sans nom qualifié (`template`, `docker_network`, `uri`) | ambiguïté de résolution, refus par le profil `production` d'`ansible-lint` | noms complets (`ansible.builtin.template`) |
| Plusieurs `ignore_errors: true` dans les gestionnaires et le tier BDD | des échecs réels passent inaperçus | remplacer par `failed_when` ciblé ou `block/rescue` |
| `no_log` présent seulement dans `tier_app.yml` | un secret peut apparaître dans la sortie d'une autre tâche | `no_log: true` sur toute tâche qui manipule un secret |
| Les gestionnaires `restart_stack`, `restart_service`, `reload_compose` ne sont pas décrits par un test | comportement non vérifié | scénario Molecule, voir le document des bonnes pratiques |

## Références

- [bonnes-pratiques-ansible.md](bonnes-pratiques-ansible.md)
- [workflow-ansible.md](workflow-ansible.md)
- Ansible, [argument_specs](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html#role-argument-validation) et [bonnes pratiques](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
