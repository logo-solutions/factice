#!/usr/bin/env bash
# Adaptateur ITSM : l'unique point d'entrée du pipeline vers l'ITSM.
# Aujourd'hui il parle au faux ITSM (itsm-mock/) ; remplacer cet adaptateur suffit
# pour passer à un vrai ITSM sans toucher au pipeline.
#
# Variables : ITSM_URL (défaut http://127.0.0.1:8095), ITSM_TOKEN (obligatoire,
#             jamais passé en argument de commande).
#
# Usage :
#   itsm.sh create <standard|normal|incident> <titre> [description] [environnement] [url CMDB]   -> affiche l'identifiant
#   itsm.sh status <ID>                       -> affiche l'état
#   itsm.sh show <ID>                         -> affiche la demande (JSON)
#   itsm.sh list [état]                       -> liste (JSON)
#   itsm.sh require-approved <ID>             -> code 0 si approuvé ou en cours, 3 sinon
#   itsm.sh approve <ID>
#   itsm.sh reject <ID> <motif>
#   itsm.sh link <ID> <empreinte> [url du run] [environnement] [url de l'élément de configuration CMDB]
#   itsm.sh close <ID> <succes|echec>        (un incident ne se clôt en succès qu'avec une fiche KB)
#   itsm.sh kb <INC-ID> <KB-NNN> [url]       -> rattache l'incident à sa fiche de Docs/kb.md
set -euo pipefail

ITSM_URL="${ITSM_URL:-http://127.0.0.1:8095}"
: "${ITSM_TOKEN:?ITSM_TOKEN doit être défini}"
[[ "$ITSM_TOKEN" =~ ^[A-Za-z0-9._~+-]+$ ]] || { echo "ITSM_TOKEN : caractères non autorisés" >&2; exit 1; }

ID_RE='^(CHG|INC)-[0-9]{4}-[0-9]{4}$'
check_id() { [[ "$1" =~ $ID_RE ]] || { echo "identifiant invalide : $1" >&2; exit 1; }; }

BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE"' EXIT

# call <méthode> <chemin> [json] : corps de la réponse sur stdout, erreur HTTP -> code 1
call() {
  local method="$1" path="$2" data="${3:-}" code
  local args=(-sS -o "$BODY_FILE" -w '%{http_code}' -X "$method" -K - "${ITSM_URL}${path}")
  if [[ -n "$data" ]]; then args+=(-H 'Content-Type: application/json' --data "$data"); fi
  code="$(printf 'header = "Authorization: Bearer %s"\n' "$ITSM_TOKEN" | curl "${args[@]}")" \
    || { echo "ITSM injoignable (${ITSM_URL})" >&2; exit 1; }
  if [[ "$code" -ge 400 ]]; then
    echo "ITSM : erreur HTTP ${code} : $(jq -r '.erreur // "inconnue"' "$BODY_FILE" 2>/dev/null || echo inconnue)" >&2
    exit 1
  fi
  cat "$BODY_FILE"
}

cmd="${1:-}"
[[ -n "$cmd" ]] || { sed -n '2,21p' "$0" >&2; exit 1; }
shift

case "$cmd" in
  create)
    [[ $# -ge 2 ]] || { echo "usage : create <type> <titre> [description] [environnement] [url CMDB]" >&2; exit 1; }
    call POST /changes "$(jq -n --arg type "$1" --arg titre "$2" --arg description "${3:-}" --arg environnement "${4:-}" --arg ci "${5:-}" \
      '{type:$type, titre:$titre, description:$description, environnement:$environnement, ci:$ci}')" | jq -r '.id'
    ;;
  status)
    [[ $# -eq 1 ]] || { echo "usage : status <ID>" >&2; exit 1; }
    check_id "$1"
    call GET "/changes/$1" | jq -r '.etat'
    ;;
  show)
    [[ $# -eq 1 ]] || { echo "usage : show <ID>" >&2; exit 1; }
    check_id "$1"
    call GET "/changes/$1" | jq .
    ;;
  list)
    if [[ -n "${1:-}" ]]; then call GET "/changes?etat=$1" | jq .; else call GET /changes | jq .; fi
    ;;
  require-approved)
    [[ $# -eq 1 ]] || { echo "usage : require-approved <ID>" >&2; exit 1; }
    check_id "$1"
    etat="$(call GET "/changes/$1" | jq -r '.etat')"
    if [[ "$etat" == "approuve" || "$etat" == "en_cours" ]]; then
      echo "$1 : ${etat}"
    else
      echo "$1 : état « ${etat} », déploiement refusé" >&2
      exit 3
    fi
    ;;
  approve)
    [[ $# -eq 1 ]] || { echo "usage : approve <ID>" >&2; exit 1; }
    check_id "$1"
    call POST "/changes/$1/approve" '{}' | jq -r '"\(.id) : \(.etat)"'
    ;;
  reject)
    [[ $# -eq 2 ]] || { echo "usage : reject <ID> <motif>" >&2; exit 1; }
    check_id "$1"
    call POST "/changes/$1/reject" "$(jq -n --arg motif "$2" '{motif:$motif}')" | jq -r '"\(.id) : \(.etat)"'
    ;;
  link)
    [[ $# -ge 2 ]] || { echo "usage : link <ID> <empreinte> [url du run] [environnement] [url CMDB]" >&2; exit 1; }
    check_id "$1"
    call POST "/changes/$1/link" "$(jq -n --arg empreinte "$2" --arg run_url "${3:-}" --arg environnement "${4:-}" --arg ci "${5:-}" \
      '{empreinte:$empreinte, run_url:$run_url, environnement:$environnement, ci:$ci}')" | jq -r '"\(.id) : \(.etat)"'
    ;;
  close)
    [[ $# -eq 2 ]] || { echo "usage : close <ID> <succes|echec>" >&2; exit 1; }
    check_id "$1"
    call POST "/changes/$1/close" "$(jq -n --arg resultat "$2" '{resultat:$resultat}')" | jq -r '"\(.id) : \(.etat)"'
    ;;
  kb)
    [[ $# -ge 2 ]] || { echo "usage : kb <INC-ID> <KB-NNN> [url]" >&2; exit 1; }
    check_id "$1"
    call POST "/changes/$1/kb" "$(jq -n --arg fiche "$2" --arg url "${3:-}" '{fiche:$fiche, url:$url}')" | jq -r '"\(.id) : fiche \(.kb[-1].fiche)"'
    ;;
  *)
    echo "commande inconnue : ${cmd}" >&2
    exit 1
    ;;
esac
