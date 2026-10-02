# Zones de sécurité

Vue d'ensemble des zones et de leurs frontières. Le détail des mesures (pare-feu, réseau Docker, TLS, moindre privilège) est dans [isolation-et-reseau.md](../4-securite/isolation-et-reseau.md) ; les flux sont dans [flux-et-reseau.md](flux-et-reseau.md).

## Zones

| Zone | Composants | Confiance | Entrées |
|---|---|---|---|
| **Internet** | GitHub | non maîtrisée | aucune vers l'hôte : le runner appelle GitHub en sortie |
| **Registry** | Nexus | maîtrisée, réseau privé | comptes de service cloisonnés (`svc-build-factice-app`, `svc-promotion`, `svc-deploiement`) |
| **Administration** | opérateurs, SSH | semi-confiance | clé SSH, comptes nominatifs |
| **Hôte** | runner, Ansible, Caddy, conteneur App, PostgreSQL | maîtrisée | Caddy `:8080` et `:9080` uniquement |

## Frontières de confiance

1. **GitHub ↔ runner** : le runner exécute le code du dépôt. Tout ce qui s'y exécute a accès aux secrets du job : seuls les événements `main` et le lancement manuel publient, déploient ou accèdent aux secrets de déploiement.
2. **Runner ↔ Nexus** : trois comptes, trois droits (écriture candidat, promotion, lecture release). Une release est immuable.
3. **Runner ↔ hôte** : le runner et Ansible partagent l'hôte avec les tiers, sans frontière d'isolation entre eux. C'est un risque accepté pour la maquette, à lever par un hôte de build séparé si l'usage sort de ce cadre.
4. **Intégration ↔ production** : mêmes hôte et même runner, mais ports, bases, utilisateurs, répertoires et secrets distincts.

## Isolation des environnements

| Élément | Intégration | Production |
|---|---|---|
| Port Caddy | 8080 | 9080 |
| Port App | 3000 | 3001 |
| PostgreSQL | 5432, `factice_integration` | 5433, `factice_production` |
| Déclenchement | automatique | manuel, environnement protégé |

## Accès d'administration

| Accès | État |
|---|---|
| Déploiement | pas d'accès distant : le workflow lance Ansible sur le runner, vers l'hôte lui-même |
| Intervention humaine sur l'hôte | session ou SSH depuis le réseau d'administration ; **aucune règle de pare-feu ni politique d'accès n'est versionnée** |
| Opérations sensibles (promotion, production) | passent par le workflow ; la production exige l'environnement protégé `production` |

Les opérations d'administration de la chaîne (workflow, secrets, runner) sont des actions d'administration à part entière : leur accès relève du même niveau de protection que l'accès à l'hôte (authentification forte, comptes nominatifs, journalisation).

## Exposition réseau

Les adresses d'écoute, le pare-feu et le TLS sont décrits, avec leurs écarts, dans [isolation-et-reseau.md](../4-securite/isolation-et-reseau.md). Point à retenir : Caddy et le port publié du conteneur App écoutent sur toutes les interfaces, ce qui élargit la zone Hôte à tout le réseau local tant qu'un pare-feu ne la restreint pas.

## Limites connues

- Pas de TLS : tout le trafic client est en HTTP.
- Écoute sur toutes les interfaces et un seul réseau Docker pour les deux environnements.
- Pas d'isolation entre le runner et les tiers.
- Menaces et mesures : [modele-menaces.md](modele-menaces.md).
- Écarts à traiter : voir le [TODO](../../TODO.md), section « Fondations ».
