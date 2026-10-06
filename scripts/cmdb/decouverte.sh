#!/usr/bin/env bash
# decouverte.sh — met la CMDB à jour depuis ce qui tourne réellement (Mac mini en local, Hetzner par SSH en lecture seule).
# Idempotent, prévu pour cron (run-job.sh). Un service CMDB = (hôte, projet, environnement) : un composant principal par projet.
# L'empreinte est l'identifiant de l'image du conteneur vivant. Les services écrits par un pipeline avec un runner
# auto-hébergé (ex. factice.app) ne sont pas dans la table : leur pipeline écrit l'empreinte exacte (référence).
# Signale : conteneurs vivants absents de la table (« non référencé ») et entrées de la table sans conteneur (« absent »).
# Codes de sortie : 0 ok, 1 erreur locale, 2 Hetzner injoignable.
# Usage : decouverte.sh [--dry-run]
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"
export DOCKER_HOST="${DOCKER_HOST:-unix://$HOME/.colima/default/docker.sock}"
CMDB_TOKEN="$(grep '^NETBOX_API_TOKEN=' .secrets/netbox.env | cut -d= -f2-)"; export CMDB_TOKEN
DRY="${1:-}"
HETZNER_SSH="${HETZNER_SSH:-hetzner}"   # alias ~/.ssh/config : utilisateur deploy, lecture seule (docker inspect)

# hôte | conteneur | projet | service | port | environnement
TABLE=(
  "macmini|maisonnettev2-caddy|maisonnettev2|caddy|8030|integration"
  "macmini|immich_server|immich|immich-server|2283|production"
  "macmini|nexus|nexus|nexus|8081|production"
  "macmini|ntfy|ntfy|ntfy|8090|production"
  "macmini|cadvisor|cadvisor|cadvisor|8080|production"
  "macmini|node_exporter|node-exporter|node-exporter|9100|production"
  "macmini|nas-logo-caddy|nas-logo|caddy|443|production"
  "macmini|factice-netbox|cmdb|netbox|8096|production"
  "macmini|factice-itsm-mock|factice-itsm-mock|itsm-mock|8095|integration"
  "macmini|autom-logo-whatsapp-bridge-1|autom-logo|whatsapp-bridge|8086|production"
  "hetzner|maisonnette-caddy|maisonnettev2|caddy|443|production"
  "hetzner|maisonnette-keycloak|idp|keycloak|443|production"
)
# conteneurs volontairement hors CMDB (composants d'un service déjà enregistré, jobs, bases, pipeline factice)
IGNORE='^(factice-|autom-logo-|nas-logo-|maisonnettev2-|maisonnette-|immich_|postgres-|elastic_|grafana|prometheus|alertmanager|paperless|sasu-|idp-)'

# état vivant : "hôte|conteneur|image"
VIVANTS="$(mktemp)"; trap 'rm -f "$VIVANTS"' EXIT
FMT='{{.Name}}|{{.Image}}'
docker ps -q | xargs -r docker inspect --format "$FMT" | sed 's#^/##; s#^#macmini|#' >>"$VIVANTS" || { echo "ERREUR : Docker local injoignable" >&2; exit 1; }
CODE=0
if H="$(ssh -o BatchMode=yes -o ConnectTimeout=15 "$HETZNER_SSH" "docker ps -q | xargs -r docker inspect --format '$FMT'" 2>/dev/null)"; then
  sed 's#^/##; s#^#hetzner|#' <<<"$H" >>"$VIVANTS"
else
  echo "ATTENTION : Hetzner injoignable ($HETZNER_SSH), entrées Hetzner non mises à jour" >&2; CODE=2
fi

REFERENCES="$(mktemp)"; trap 'rm -f "$VIVANTS" "$REFERENCES"' EXIT
for ligne in "${TABLE[@]}"; do
  IFS='|' read -r hote conteneur projet service port env <<<"$ligne"
  echo "$hote|$conteneur" >>"$REFERENCES"
  empreinte="$(awk -F'|' -v h="$hote" -v c="$conteneur" '$1==h && $2==c {print $3}' "$VIVANTS")"
  if [ -z "$empreinte" ]; then
    # hôte joignable mais conteneur arrêté : absent ; hôte injoignable : on ne touche à rien
    if [ "$hote" = "hetzner" ] && [ "$CODE" = 2 ]; then continue; fi
    echo "ABSENT      $projet ($env) sur $hote : conteneur $conteneur arrêté"; continue
  fi
  if [ "$DRY" = "--dry-run" ]; then
    echo "[essai]     $projet ($env) sur $hote :$port ${empreinte:0:19}"
  else
    ./scripts/cmdb/cmdb.sh register-service "$projet" "$hote" "$service" "$port" "$empreinte" "$env" >/dev/null \
      && echo "OK          $projet ($env) sur $hote :$port" || echo "ERREUR      $projet ($env) sur $hote" >&2
  fi
done

while IFS='|' read -r hote conteneur _; do
  grep -qxF "$hote|$conteneur" "$REFERENCES" && continue
  [[ "$conteneur" =~ $IGNORE ]] && continue
  echo "NON RÉFÉRENCÉ  $conteneur sur $hote (ajouter à TABLE ou à IGNORE)"
done <"$VIVANTS"
exit "$CODE"
