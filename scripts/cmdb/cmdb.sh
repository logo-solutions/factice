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
#   cmdb.sh register-service <projet> <hote> <service> <port> <empreinte> [env] [tag] [owner] [status] [deployed_by]
#                                                   -> crée ou met à jour le service déployé ;
#                                                      affiche l'URL de l'élément de configuration
#   cmdb.sh get-service <projet> <service> [environnement]   -> JSON complet du service
#   cmdb.sh ci-url <projet> <service> [environnement]   -> URL de l'élément de configuration (vide si inconnu)
#   cmdb.sh list [projet]                           -> services connus (projet, hote, service, env, empreinte, status)
#   cmdb.sh set-health <projet> <service> <status> [response_time_ms]  -> met à jour l'état health
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

    # Champs custom de base
    for f in projet empreinte environnement image_tag image_digest sbom_hash owner status deployed_by; do
      ensure /api/extras/custom-fields/ "name=$f" \
        "$(jq -n --arg n "$f" '{object_types:["ipam.service"],name:$n,label:$n,type:"text"}')" >/dev/null
    done

    # Champs custom pour santé et compliance
    for f in healthcheck_endpoint healthcheck_status response_time_ms compliance_status tls_certificate_expiry; do
      ensure /api/extras/custom-fields/ "name=$f" \
        "$(jq -n --arg n "$f" '{object_types:["ipam.service"],name:$n,label:$n,type:"text"}')" >/dev/null
    done

    # Champs custom pour ressources
    for f in cpu_requested memory_requested storage_class deployed_at; do
      ensure /api/extras/custom-fields/ "name=$f" \
        "$(jq -n --arg n "$f" '{object_types:["ipam.service"],name:$n,label:$n,type:"text"}')" >/dev/null
    done

    echo "modèle prêt ($(api GET /api/extras/custom-fields/ "" "limit=100" | jq '.count') custom fields)"
    ;;
  register-service)
    [[ $# -ge 5 ]] || { echo "usage : register-service <projet> <hote> <service> <port> <empreinte> [env] [tag] [owner] [status] [deployed_by]" >&2; exit 1; }
    projet="$1" hote="$2" service="$3" port="$4" empreinte="$5"
    env="${6:-}"
    tag="${7:-}"
    owner="${8:-}"
    status="${9:-active}"
    deployed_by="${10:-}"

    [[ "$port" =~ ^[0-9]{1,5}$ ]] || { echo "port invalide" >&2; exit 1; }

    site="$(ensure /api/dcim/sites/ "slug=factice" '{}')"
    dtype="$(ensure /api/dcim/device-types/ "slug=serveur" '{}')"
    role="$(ensure /api/dcim/device-roles/ "slug=hote" '{}')"
    dev="$(ensure /api/dcim/devices/ "name=$hote" \
      "$(jq -n --arg n "$hote" --argjson t "$dtype" --argjson r "$role" --argjson s "$site" \
        '{name:$n,device_type:$t,role:$r,site:$s,status:"active"}')")"

    # Construire les custom fields avec tous les attributs
    cf="$(jq -n \
      --arg p "$projet" \
      --arg e "$empreinte" \
      --arg v "$env" \
      --arg tag "$tag" \
      --arg owner "$owner" \
      --arg status "$status" \
      --arg deployed_by "$deployed_by" \
      --arg deployed_at "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
      '{
        projet: $p,
        empreinte: $e,
        environnement: $v,
        image_tag: $tag,
        owner: $owner,
        status: $status,
        deployed_by: $deployed_by,
        deployed_at: $deployed_at
      }')"

    existing="$(api GET /api/ipam/services/ "" "name=$service" \
      | jq -r --arg p "$projet" --arg v "$env" --argjson d "$dev" \
        '[.results[] | select(.parent.id==$d and .custom_fields.projet==$p and (.custom_fields.environnement // "")==$v)][0].id // empty')"

    payload="$(jq -n --arg n "$service" --argjson d "$dev" --argjson port "$port" --argjson cf "$cf" \
      '{name:$n,parent_object_type:"dcim.device",parent_object_id:$d,protocol:"tcp",ports:[$port],custom_fields:$cf}')"

    if [[ -n "$existing" ]]; then
      api PATCH "/api/ipam/services/${existing}/" "$payload" >/dev/null
      id="$existing"
      echo "service mis à jour : ${projet}/${service} v${tag:-?} sur ${hote}:${port} (id ${id})" >&2
    else
      id="$(api POST /api/ipam/services/ "$payload" | jq -r '.id')"
      echo "service créé : ${projet}/${service} v${tag:-?} sur ${hote}:${port} (id ${id})" >&2
    fi
    echo "${CMDB_URL}/ipam/services/${id}/"
    ;;
  get-service)
    [[ $# -ge 2 ]] || { echo "usage : get-service <projet> <service> [environnement]" >&2; exit 1; }
    api GET /api/ipam/services/ "" "name=$2" \
      | jq --arg p "$1" --arg v "${3:-}" \
        '[.results[] | select(.custom_fields.projet==$p and ($v=="" or .custom_fields.environnement==$v))][0] // empty
         | {
            id,
            projet:.custom_fields.projet,
            service:.name,
            hote:.parent.name,
            port:.ports[0],
            environnement:.custom_fields.environnement,
            empreinte:.custom_fields.empreinte,
            image_tag:.custom_fields.image_tag,
            image_digest:.custom_fields.image_digest,
            owner:.custom_fields.owner,
            status:.custom_fields.status,
            deployed_by:.custom_fields.deployed_by,
            deployed_at:.custom_fields.deployed_at,
            healthcheck_endpoint:.custom_fields.healthcheck_endpoint,
            healthcheck_status:.custom_fields.healthcheck_status,
            response_time_ms:.custom_fields.response_time_ms,
            compliance_status:.custom_fields.compliance_status,
            cpu_requested:.custom_fields.cpu_requested,
            memory_requested:.custom_fields.memory_requested,
            storage_class:.custom_fields.storage_class,
            maj:.last_updated
           }'
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
         | [.custom_fields.projet, .parent.name, .name, (.custom_fields.environnement // "-"), (.custom_fields.status // "?"), (.custom_fields.empreinte // "-")] | @tsv'
    ;;
  set-health)
    [[ $# -ge 3 ]] || { echo "usage : set-health <projet> <service> <status> [response_time_ms]" >&2; exit 1; }
    projet="$1" service="$2" health_status="$3" response_time="${4:-}"

    svc="$("$0" get-service "$projet" "$service" | jq -r '.id // empty')"
    [[ -n "$svc" ]] || { echo "service non trouvé : ${projet}/${service}" >&2; exit 1; }

    cf="$(jq -n \
      --arg status "$health_status" \
      --arg time "$response_time" \
      '{
        healthcheck_status: $status,
        response_time_ms: $time
      }')"

    payload="$(jq -n --argjson cf "$cf" '{custom_fields:$cf}')"
    api PATCH "/api/ipam/services/${svc}/" "$payload" >/dev/null
    echo "santé mise à jour : ${projet}/${service} → ${health_status} ${response_time:+(${response_time}ms)}" >&2
    ;;
  update-service)
    [[ $# -ge 3 ]] || { echo "usage : update-service <projet> <service> <key=value> [key=value...]" >&2; exit 1; }
    projet="$1" service="$2"
    shift 2

    svc="$("$0" get-service "$projet" "$service" | jq -r '.id // empty')"
    [[ -n "$svc" ]] || { echo "service non trouvé : ${projet}/${service}" >&2; exit 1; }

    # Construire un objet JSON à partir des paires key=value
    cf='{}'
    for arg in "$@"; do
      key="${arg%%=*}"
      val="${arg#*=}"
      cf="$(jq -n --argjson cf "$cf" --arg k "$key" --arg v "$val" '$cf + {($k): $v}')"
    done

    payload="$(jq -n --argjson cf "$cf" '{custom_fields:$cf}')"
    api PATCH "/api/ipam/services/${svc}/" "$payload" >/dev/null
    echo "service mis à jour : ${projet}/${service}" >&2
    ;;
  *)
    echo "commande inconnue : ${cmd}" >&2
    exit 1
    ;;
esac
