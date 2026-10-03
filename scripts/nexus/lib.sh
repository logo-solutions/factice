#!/usr/bin/env bash
# Fonctions communes aux scripts de la chaîne de livraison Nexus.
# Les secrets arrivent par l'environnement (NEXUS_USER / NEXUS_PASSWORD) et ne
# transitent jamais par les arguments de commande ni par les journaux.
set -euo pipefail

NEXUS_URL="${NEXUS_URL:-http://localhost:8081}"
NEXUS_API="${NEXUS_URL}/service/rest/v1"
# Un point d'accès Docker par dépôt (spec 3.3). Valeurs par défaut de la maquette.
NEXUS_DOCKER_CANDIDAT="${NEXUS_DOCKER_CANDIDAT:-localhost:5001}"
NEXUS_DOCKER_RELEASE="${NEXUS_DOCKER_RELEASE:-localhost:5002}"

log() { printf '[%s] %s\n' "$(basename "$0")" "$*" >&2; }
die() { log "ERREUR : $*"; exit 1; }

require() {
  local v
  for v in "$@"; do
    [ -n "${!v:-}" ] || die "variable obligatoire absente : $v"
  done
}

require_tools() {
  local t
  for t in "$@"; do command -v "$t" >/dev/null || die "outil manquant : $t"; done
}

# Fichier netrc éphémère (mode 600) : évite le mot de passe en argument curl.
_NETRC=""
init_auth() {
  require NEXUS_USER NEXUS_PASSWORD
  _NETRC="$(mktemp)"
  chmod 600 "$_NETRC"
  local host
  host="$(printf '%s' "$NEXUS_URL" | sed -E 's#^[a-z]+://([^/:]+).*#\1#')"
  printf 'machine %s login %s password %s\n' "$host" "$NEXUS_USER" "$NEXUS_PASSWORD" > "$_NETRC"
  trap '_cleanup_auth' EXIT
}
_cleanup_auth() { [ -z "$_NETRC" ] || rm -f "$_NETRC"; }

# nexus_curl <args curl…> : appel authentifié, échoue sur code HTTP >= 400.
nexus_curl() { curl -sS --fail-with-body --netrc-file "$_NETRC" "$@"; }

# Chemin raw d'un composant : <application>/<composant>/<version>/<fichier>
raw_path() { printf '%s/%s/%s/%s' "$1" "$2" "$3" "$4"; }

raw_put() {  # raw_put <dépôt> <chemin> <fichier local>
  nexus_curl -o /dev/null --upload-file "$3" "${NEXUS_URL}/repository/$1/$2"
}

raw_get() {  # raw_get <dépôt> <chemin> <fichier de sortie> ; code retour 22 si absent
  curl -sS --fail --netrc-file "$_NETRC" -o "$3" "${NEXUS_URL}/repository/$1/$2" 2>/dev/null
}

raw_exists() {  # raw_exists <dépôt> <chemin>
  curl -sS --fail -o /dev/null -I --netrc-file "$_NETRC" "${NEXUS_URL}/repository/$1/$2" 2>/dev/null
}

raw_delete() {  # raw_delete <dépôt> <chemin> (nettoyage d'une publication partielle)
  curl -sS -o /dev/null -X DELETE --netrc-file "$_NETRC" "${NEXUS_URL}/repository/$1/$2" || true
}

sha256_of() { shasum -a 256 "$1" | cut -d' ' -f1; }

docker_login() {  # docker_login <hôte:port> : mot de passe par l'entrée standard
  printf '%s' "$NEXUS_PASSWORD" | docker login "$1" -u "$NEXUS_USER" --password-stdin >/dev/null
}
