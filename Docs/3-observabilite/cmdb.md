# CMDB : inventaire de ce qui est réellement déployé

La CMDB de factice est **NetBox** (4.4), derrière l'adaptateur `scripts/cmdb/cmdb.sh`. Elle est conçue pour accueillir l'ensemble des projets, pas seulement factice. Mise en route et exploitation : [netbox/README.md](../../netbox/README.md). Place dans la chaîne : [flux-outils-factice.md](../1-fondations/flux-outils-factice.md) (flux 10, 11, 12).

## Principes

- **Le pipeline écrit, la CMDB ne se saisit pas à la main** : chaque déploiement réussi met à jour l'empreinte déployée (décision 2 de [flux-outils.md](../1-fondations/flux-outils.md)).
- **Un seul propriétaire par attribut** : `empreinte` et `environnement` sont écrits par le pipeline uniquement.
- **La CMDB stocke l'empreinte, jamais le SBOM** (décision 3) : le SBOM reste dans le registry.

## Modèle

| Notion | Objet NetBox | Attributs |
|---|---|---|
| Hôte (`macmini`) | Device | site `factice`, rôle `hote` |
| Service déployé | Service rattaché à l'hôte | `projet`, `environnement`, `empreinte`, port |

Un service est identifié par le triplet (hôte, projet, environnement). Le projet porte l'identifiant d'application du pipeline (`factice.app`), le service le nom du composant (`factice`).

## Contrat de l'adaptateur

| Commande | Effet |
|---|---|
| `init` | prépare le modèle, idempotent |
| `register-service <projet> <hôte> <service> <port> <empreinte> [env]` | crée ou met à jour ; affiche l'URL de l'élément de configuration |
| `get-service <projet> <service> [env]` | JSON du service |
| `list [projet]` | services connus |
| `reconcile.sh [projet]` | vérifie que chaque empreinte existe dans le registry, code 2 sinon |

## Étendre à d'autres projets

Pour inventorier un autre projet, appeler `register-service` avec son identifiant d'application et son hôte, depuis son pipeline. Aucun changement de modèle. Ajouter des hôtes (Hetzner) revient à les nommer dans l'appel.

## Limites

Un jeton d'administration unique, un rapprochement manuel à sens unique, pas de relations entre services (dépendances). Voir les écarts dans [flux-outils-factice.md](../1-fondations/flux-outils-factice.md).
