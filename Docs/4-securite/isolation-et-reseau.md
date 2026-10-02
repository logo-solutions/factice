# Isolation et réseau

Ce document décrit l'isolation **réelle** de factice, puis l'écart avec la cible. Les zones et leurs frontières sont dans [zones-securite.md](../1-fondations/zones-securite.md), les flux dans [flux-et-reseau.md](../1-fondations/flux-et-reseau.md), les menaces dans [modele-menaces.md](../1-fondations/modele-menaces.md).

## Ce qui est en place

| Mesure | Détail |
|---|---|
| Aucun accès entrant depuis Internet | le runner appelle GitHub en sortie ; pas de webhook |
| Environnements cloisonnés | ports, bases, utilisateurs, répertoires, étiquettes de LaunchAgent distincts |
| Interface d'administration de Caddy désactivée | `admin off` dans le Caddyfile |
| En-têtes de réponse de base | `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, suppression de l'en-tête `Server` |
| Journaux d'accès au format JSON | avec rotation (100 Mio, trois fichiers, 720 h) lorsque activés |
| Comptes Nexus cloisonnés | écriture candidat, promotion, lecture release |
| Image tirée par empreinte | ce qui tourne est ce qui a été promu |
| Fichiers de secrets en mode `0600` | `.env` rendu par Ansible |

## Ports et exposition

| Élément | Intégration | Production | Écoute réelle |
|---|---|---|---|
| Caddy | 8080 | 9080 | `http://:PORT` : **toutes les interfaces** de l'hôte |
| Conteneur App | 3000 | 3001 | `"PORT_HÔTE:PORT_INTERNE"` dans le fichier Compose : **toutes les interfaces**, sans liaison à `127.0.0.1` |
| PostgreSQL natif | 5432 | 5433 | configuration par défaut de l'installation |
| Interface d'administration Caddy | — | — | désactivée |

Deux conséquences :

- le conteneur App est joignable directement, **sans passer par Caddy**, depuis toute machine qui atteint l'hôte ; les en-têtes de Caddy et ses journaux sont alors contournés ;
- si le pare-feu n'est pas actif, Caddy est joignable depuis tout le réseau local, pas seulement depuis le réseau d'administration.

**Cible.**

- lier le port publié du conteneur à l'interface locale : `"127.0.0.1:3000:3000"` ; Caddy joint le conteneur par `localhost` ;
- faire écouter Caddy sur l'interface voulue plutôt que sur toutes (`http://127.0.0.1:PORT` ou l'adresse du réseau d'administration) ;
- vérifier l'adresse d'écoute de PostgreSQL (`listen_addresses`) et la restreindre à `localhost` ;
- vérifier l'exposition réelle par un balayage depuis une autre machine du réseau (`nmap`), sans se fier à la seule configuration.

## Réseau Docker

Les deux environnements utilisent le **même** réseau Docker `factice-network` (variable `factice_docker_network`). Il n'y a donc pas d'isolation réseau entre l'App d'intégration et celle de production au niveau de Docker : l'isolation repose sur les ports, les bases et les identifiants.

**Cible.** Un réseau par environnement (`factice-integration`, `factice-production`), pour que les conteneurs des deux environnements ne se voient pas.

## Pare-feu

Sur macOS, le filtrage s'appuie sur le pare-feu applicatif et sur `pf`, pas sur UFW. La règle de principe : **tout refuser par défaut**, puis autoriser explicitement.

| Flux à autoriser | Source | Destination |
|---|---|---|
| HTTP vers l'application | réseau d'administration | ports Caddy 8080 et 9080 |
| SSH d'administration | réseau d'administration | port 22 |
| Tout le reste en entrée | — | refusé |

**État.** Aucune règle n'est décrite ni versionnée dans le dépôt. **Cible.** Un fichier de règles `pf` versionné, chargé au démarrage, et vérifié par balayage. Les règles `pf` restent à rédiger ; elles ne sont pas fournies ici.

## TLS

| Environnement | État | Cible |
|---|---|---|
| Intégration | HTTP, local | HTTP acceptable en local ; certificat local (par exemple `mkcert`) si l'accès sort de la machine |
| Production | **HTTP** : `auto_https off`, écoute `http://:9080` | HTTPS avec un certificat valide dès que l'application est atteinte par un autre chemin que la machine elle-même |

Le Caddyfile actuel désactive volontairement HTTPS automatique : la maquette n'est pas exposée sur Internet. Si elle l'était, il faudrait un nom de domaine, les ports 80 et 443, la gestion des certificats par Caddy (ACME), la redirection de HTTP vers HTTPS et l'en-tête `Strict-Transport-Security`. Aucune de ces conditions n'est remplie aujourd'hui ; ne pas décrire la production comme chiffrée.

## Moindre privilège

| Acteur | Ressource | État actuel | Cible |
|---|---|---|---|
| Compte de build | Nexus | écriture dans `docker-candidat` uniquement | idem |
| Compte de promotion | Nexus | lecture candidat, écriture release | idem |
| Compte de déploiement | Nexus | lecture seule de la release | idem |
| Utilisateur applicatif PostgreSQL | base de l'environnement | **propriétaire** de la base (`createdb -O`) : peut modifier le schéma | deux rôles : un propriétaire pour les migrations, un rôle applicatif limité à `SELECT`, `INSERT`, `UPDATE`, `DELETE` |
| Création de l'utilisateur et de la base | tier BDD | commande `shell` avec le mot de passe dans la ligne de commande et erreurs ignorées | module PostgreSQL d'Ansible, `no_log`, erreurs non masquées |
| Conteneur App | système de fichiers | utilisateur non privilégié déclaré (`user:`) | système de fichiers en lecture seule, capacités retirées |
| Runner | hôte | même hôte et mêmes droits que les tiers | compte dédié, voir [securite-pipeline.md](../2-pipeline-livraison/ci-cd/securite-pipeline.md) |

## Prochaines étapes

1. Lier les ports aux interfaces locales ; un réseau Docker par environnement.
2. Rédiger et versionner les règles de pare-feu ; vérifier par balayage.
3. Séparer le rôle propriétaire du rôle applicatif PostgreSQL.
4. Décider de la politique TLS selon le mode d'accès réel.
5. Tester l'isolation entre intégration et production (accès croisé).

## Références

- NIST, [SP 800-207 Zero Trust Architecture](https://csrc.nist.gov/pubs/sp/800/207/final)
- CISA, [Microsegmentation in Zero Trust](https://www.cisa.gov/resources-tools/resources/microsegmentation-zero-trust-part-one-introduction-and-planning)
- Caddy, [Automatic HTTPS](https://caddyserver.com/docs/automatic-https)
- Docker, [Packet filtering and firewalls](https://docs.docker.com/engine/network/packet-filtering-firewalls/) (les ports publiés contournent les règles de pare-feu de l'hôte sous Linux ; sous macOS, vérifier par balayage)
