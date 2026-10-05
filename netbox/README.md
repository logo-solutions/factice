# CMDB NetBox

Vraie CMDB (NetBox 4.4) pour l'ensemble de l'écosystème, pas un double de test. Elle reçoit l'inventaire des déploiements (flux 10 : Ansible → CMDB) et alimentera l'ITSM (flux 12). Voir `Docs/1-fondations/flux-outils.md`.

Le pipeline et les playbooks ne parlent jamais à NetBox directement : ils passent par `scripts/cmdb/cmdb.sh`. Changer d'outil = réécrire cet adaptateur.

## Modèle

| Notion | Objet NetBox |
|---|---|
| Hôte (Mac Mini, Hetzner…) | Device (site `factice`, rôle `hote`) |
| Service déployé | Service rattaché à l'hôte, avec champs personnalisés `projet`, `environnement`, `empreinte` (digest de l'image) |

`cmdb.sh init` crée ce modèle (idempotent). `register-service` crée ou met à jour un service : à appeler après chaque déploiement avec l'empreinte déployée.

## Secrets

Fichier `.secrets/netbox.env` (ignoré par git, droits 600), variables : `NETBOX_SECRET_KEY`, `NETBOX_DB_PASSWORD`, `NETBOX_REDIS_PASSWORD`, `NETBOX_SUPERUSER_PASSWORD`, `NETBOX_API_TOKEN` (40 caractères). Génération :

```bash
mkdir -p .secrets && umask 077
{ echo "NETBOX_SECRET_KEY=$(openssl rand -hex 40)"
  echo "NETBOX_DB_PASSWORD=$(openssl rand -hex 16)"
  echo "NETBOX_REDIS_PASSWORD=$(openssl rand -hex 16)"
  echo "NETBOX_SUPERUSER_PASSWORD=$(openssl rand -hex 12)"
  echo "NETBOX_API_TOKEN=$(openssl rand -hex 20)"; } > .secrets/netbox.env
```

Ces valeurs ne se committent jamais. À sauvegarder dans Bitwarden.

## Lancer

```bash
cd netbox
docker compose --env-file ../.secrets/netbox.env up -d
# interface : http://127.0.0.1:8096  (utilisateur admin, mot de passe NETBOX_SUPERUSER_PASSWORD)
```

Premier démarrage : compter 2 à 3 minutes (migrations). Port lié à `127.0.0.1` uniquement ; pour l'exposer, passer par Caddy avec TLS.

## Utiliser

```bash
set -a; . .secrets/netbox.env; set +a
export CMDB_TOKEN=$NETBOX_API_TOKEN
scripts/cmdb/cmdb.sh init
scripts/cmdb/cmdb.sh register-service factice macmini factice-app 3000 sha256:abc1234 integration
scripts/cmdb/cmdb.sh get-service factice factice-app integration
scripts/cmdb/cmdb.sh list
```

## Limites

Un seul jeton d'administration pour l'instant : créer des jetons restreints (écriture pour Ansible, lecture pour l'ITSM) dans l'interface avant d'ouvrir à d'autres usages (ACC-07). Sauvegarde : volumes Docker `netbox-pgdata` et `netbox-media`, à intégrer aux sauvegardes du Mac Mini.

## Rapprochement avec le registry

`scripts/cmdb/reconcile.sh` vérifie que chaque empreinte inscrite dans la CMDB existe dans le registry de releases (compte Nexus en lecture seule via `NEXUS_USER` / `NEXUS_PASSWORD`). Code de sortie 2 en cas d'écart. Voir [flux-outils-factice.md](../Docs/1-fondations/flux-outils-factice.md).
