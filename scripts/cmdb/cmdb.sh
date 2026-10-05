#!/usr/bin/env bash
# Adaptateur CMDB : l'unique point d'entrée des pipelines et playbooks vers la CMDB
# (flux 10 : Ansible -> CMDB). Aujourd'hui il parle à NetBox (netbox/) ; remplacer
# cet adaptateur suffit pour changer d'outil sans toucher aux appelants.
#
# Variables : CMDB_URL (défaut http://127.0.0.1:8096), CMDB_TOKEN (obligatoire,
#             jamais passé en argument de commande).
#
# Usage :
#   cmdb.sh init                                    -> prépare le modèle (idempotent)
#   cmdb.sh register-service <projet> <hote> <service> <port> <empreinte> [environnement]
#                                                   -> crée ou met à jour le service déployé ;
#                                                      affiche l'URL de l'élément de configuration
#   cmdb.sh get-service <projet> <service> [environnement]   -> JSON du service
#   cmdb.sh ci-url <projet> <service> [environnement]   -> URL de l'élément de configuration (vide si inconnu)
#   cmdb.sh list [projet]                           -> services connus (projet, hote, service, env, empreinte)
set -euo pipefail

CMDB_URL="${CMDB_URL:-http://127.0.0.1:8096}"
: "${CMDB_TOKEN:?CMDB_TOKEN doit être défini}"
[[ "$CMDB_TOKEN" =~ ^[A-Za-z0-9._~+-]+$ ]] || { echo "CMDB_TOKEN : caractères non autorisés" >&2; exit 1; }

BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT

# api <méthode> <chemin> [json] [requête] : corps sur stdout, erreur HTTP -> code 1
api() {
  local method="$1" path="$2" data="${3:-}" query="${4:-}" code
  local args=(-sS -o "$BODY_FILE" -w '%{http_code}' -X "$method" -K - -H 'Accept: application/json')
  if [[ -n "$query" ]]; then args+=(--get --data-urlencode "$query"); fi
  if [[ -n "$data" ]]; then args+=(-H 'Content-Type: application/json' --data "$data"); fi
  args+=("${CMDB_URL}${path}")
  code="$(printf 'header = "Authorization: Token %s"\n' "$CMDB_TOKEN" | curl "${args[@]}")" \
    || { echo "CMDB injoignable (${CMDB_URL})" >&2; exit 1; }
  if [[ "$code" -ge 400 ]]; then
    echo "CMDB : erreur HTTP ${code} sur ${method} ${path} : $(head -c 400 "$BODY_FILE")" >&2
    exit 1
  fi
  cat "$BODY_FILE"
}

slug() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9\n' '-' | sed 's/^-*//;s/-*$//'; }

# ensure <chemin> <filtre clé=valeur> <json de création> : renvoie l'identifiant
ensure() {
  local path="$1" filter="$2" create="$3" id
  id="$(api GET "$path" "" "$filter" | jq -r '.results[0].id // empty')"
  if [[ -z "$id" ]]; then id="$(api POST "$path" "$create" | jq -r '.id')"; fi
  echo "$id"
}

cmd="${1:-}"
[[ -n "$cmd" ]] || { sed -n '2,15p' "$0" >&2; exit 1; }
shift

case "$cmd" in
  init)
    api GET /api/status/ >/dev/null
    ensure /api/dcim/sites/ "slug=factice" '{"name":"Factice","slug":"factice","status":"active"}' >/dev/null
    ensure /api/dcim/manufacturers/ "slug=generique" '{"name":"Générique","slug":"generique"}' >/dev/null
    mf="$(ensure /api/dcim/manufacturers/ "slug=generique" '{}')"
    ensure /api/dcim/device-types/ "slug=serveur" "$(jq -n --argjson m "$mf" '{manufacturer:$m,model:"Serveur",slug:"serveur"}')" >/dev/null
    ensure /api/dcim/device-roles/ "slug=hote" '{"name":"Hôte","slug":"hote","color":"2196f3"}' >/dev/null
    for f in projet empreinte environnement; do
      ensure /api/extras/custom-fields/ "name=$f" \
        "$(jq -n --arg n "$f" '{object_types:["ipam.service"],name:$n,label:$n,type:"text"}')" >/dev/null
    done
    echo "modèle prêt"
    ;;
  register-service)
    [[ $# -ge 5 ]] || { echo "usage : register-service <projet> <hote> <service> <port> <empreinte> [environnement]" >&2; exit 1; }
    projet="$1" hote="$2" service="$3" port="$4" empreinte="$5" env="${6:-}"
    [[ "$port" =~ ^[0-9]{1,5}$ ]] || { echo "port invalide" >&2; exit 1; }
    site="$(ensure /api/dcim/sites/ "slug=factice" '{}')"
    dtype="$(ensure /api/dcim/device-types/ "slug=serveur" '{}')"
    role="$(ensure /api/dcim/device-roles/ "slug=hote" '{}')"
    dev="$(ensure /api/dcim/devices/ "name=$hote" \
      "$(jq -n --arg n "$hote" --argjson t "$dtype" --argjson r "$role" --argjson s "$site" \
        '{name:$n,device_type:$t,role:$r,site:$s,status:"active"}')")"
    cf="$(jq -n --arg p "$projet" --arg e "$empreinte" --arg v "$env" '{projet:$p,empreinte:$e,environnement:$v}')"
    existing="$(api GET /api/ipam/services/ "" "name=$service" \
      | jq -r --arg p "$projet" --arg v "$env" --argjson d "$dev" \
        '[.results[] | select(.parent.id==$d and .custom_fields.projet==$p and (.custom_fields.environnement // "")==$v)][0].id // empty')"
    payload="$(jq -n --arg n "$service" --argjson d "$dev" --argjson port "$port" --argjson cf "$cf" \
      '{name:$n,parent_object_type:"dcim.device",parent_object_id:$d,protocol:"tcp",ports:[$port],custom_fields:$cf}')"
    if [[ -n "$existing" ]]; then
      api PATCH "/api/ipam/services/${existing}/" "$payload" >/dev/null
      id="$existing"
      echo "service mis à jour : ${projet}/${service} sur ${hote} (id ${id})" >&2
    else
      id="$(api POST /api/ipam/services/ "$payload" | jq -r '.id')"
      echo "service créé : ${projet}/${service} sur ${hote} (id ${id})" >&2
    fi
    echo "${CMDB_URL}/ipam/services/${id}/"
    ;;
  get-service)
    [[ $# -ge 2 ]] || { echo "usage : get-service <projet> <service> [environnement]" >&2; exit 1; }
    api GET /api/ipam/services/ "" "name=$2" \
      | jq --arg p "$1" --arg v "${3:-}" \
        '[.results[] | select(.custom_fields.projet==$p and ($v=="" or .custom_fields.environnement==$v))][0] // empty
         | {id, projet:.custom_fields.projet, service:.name, hote:.parent.name, port:.ports[0],
            environnement:.custom_fields.environnement, empreinte:.custom_fields.empreinte, maj:.last_updated}'
    ;;
  ci-url)
    [[ $# -ge 2 ]] || { echo "usage : ci-url <projet> <service> [environnement]" >&2; exit 1; }
    id="$("$0" get-service "$@" | jq -r '.id // empty')"
    [[ -z "$id" ]] || echo "${CMDB_URL}/ipam/services/${id}/"
    ;;
  list)
    api GET /api/ipam/services/ "" "limit=500" \
      | jq -r --arg p "${1:-}" \
        '.results[] | select($p=="" or .custom_fields.projet==$p)
         | [.custom_fields.projet, .parent.name, .name, (.custom_fields.environnement // "-"), (.custom_fields.empreinte // "-")] | @tsv'
    ;;
  *)
    echo "commande inconnue : ${cmd}" >&2
    exit 1
    ;;
esac
