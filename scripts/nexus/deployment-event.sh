#!/usr/bin/env bash
# Événement de déploiement (spec 8.2), émis à chaque déploiement, réussi ou non.
# Variables : APP_ID, COMPONENT, VERSION, DIGEST, ENVIRONMENT, RESULT
#             (reussi|echoue|retour-arriere), EVENT_LOG (journal local, défaut
#             deploy-events.jsonl), CMDB_EVENT_URL + CMDB_TOKEN (facultatifs)
set -euo pipefail
. "$(dirname "$0")/lib.sh"
require APP_ID COMPONENT VERSION DIGEST ENVIRONMENT RESULT
case "$RESULT" in reussi|echoue|retour-arriere) ;; *) die "RESULT invalide : $RESULT" ;; esac
require_tools jq

EVENT="$(jq -nc --arg app "$APP_ID" --arg env "$ENVIRONMENT" --arg comp "$COMPONENT" \
  --arg ver "$VERSION" --arg digest "$DIGEST" --arg res "$RESULT" \
  --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{
    application: $app, environnement: $env,
    release: {composant: $comp, version: $ver, empreinte: $digest},
    imagesDorees: [], date: $date, resultat: $res}')"

printf '%s\n' "$EVENT" >> "${EVENT_LOG:-deploy-events.jsonl}"
log "événement enregistré : ${APP_ID} ${VERSION} ${ENVIRONMENT} ${RESULT}"

if [ -n "${CMDB_EVENT_URL:-}" ]; then
  curl -sS --fail-with-body -X POST -H 'Content-Type: application/json' \
    ${CMDB_TOKEN:+-H "Authorization: Bearer ${CMDB_TOKEN}"} \
    --data "$EVENT" "$CMDB_EVENT_URL" >/dev/null
  log "événement transmis à la CMDB"
fi
