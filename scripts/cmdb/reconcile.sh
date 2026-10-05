#!/usr/bin/env bash
# Rapprochement registry / CMDB (flux 11) : chaque empreinte déclarée dans la CMDB
# doit exister dans le registry de releases. Code de sortie 2 si au moins un écart.
#
# Usage : reconcile.sh [projet]      (défaut : factice.app, l'APP_ID du pipeline)
# Variables : CMDB_URL, CMDB_TOKEN (voir cmdb.sh)
#             NEXUS_DOCKER_RELEASE (défaut localhost:5002), NEXUS_SCHEME (défaut http)
#             NEXUS_USER + NEXUS_PASSWORD (compte en lecture seule, jamais en argument)
# Le nom d'image attendu est <registry>/<projet>/<service>@<empreinte>.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PROJET="${1:-factice.app}"
REGISTRY="${NEXUS_DOCKER_RELEASE:-localhost:5002}"
SCHEME="${NEXUS_SCHEME:-http}"
: "${NEXUS_USER:?NEXUS_USER doit être défini}"
: "${NEXUS_PASSWORD:?NEXUS_PASSWORD doit être défini}"
[[ "$NEXUS_USER" =~ ^[A-Za-z0-9._@-]+$ ]] || { echo "NEXUS_USER : caractères non autorisés" >&2; exit 1; }
[[ "$NEXUS_PASSWORD" != *'"'* && "$NEXUS_PASSWORD" != *$'\n'* ]] || { echo "NEXUS_PASSWORD : caractères non autorisés" >&2; exit 1; }

ACCEPT='application/vnd.oci.image.manifest.v1+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.docker.distribution.manifest.list.v2+json'
ecarts=0
total=0

while IFS=$'\t' read -r projet hote service env empreinte; do
  [[ "$projet" == "$PROJET" ]] || continue
  total=$((total + 1))
  if [[ ! "$empreinte" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    echo "ECART  ${projet}/${service} (${env}) sur ${hote} : empreinte non exploitable « ${empreinte} »"
    ecarts=$((ecarts + 1))
    continue
  fi
  code="$(printf 'user = "%s:%s"\n' "$NEXUS_USER" "$NEXUS_PASSWORD" \
    | curl -sS -o /dev/null -w '%{http_code}' -I -K - -H "Accept: ${ACCEPT}" \
        "${SCHEME}://${REGISTRY}/v2/${projet}/${service}/manifests/${empreinte}")" \
    || { echo "registry injoignable (${REGISTRY})" >&2; exit 1; }
  if [[ "$code" == "200" ]]; then
    echo "OK     ${projet}/${service} (${env}) sur ${hote} : ${empreinte:0:19}"
  else
    echo "ECART  ${projet}/${service} (${env}) sur ${hote} : empreinte absente du registry (HTTP ${code})"
    ecarts=$((ecarts + 1))
  fi
done < <("$HERE/cmdb.sh" list)

echo "rapprochement : ${total} service(s), ${ecarts} écart(s)"
[[ "$ecarts" -eq 0 ]] || exit 2
