#!/usr/bin/env bash
# Publication d'un composant interne en candidat (spec 6.1, 8.1).
# Compte attendu : le compte de build de l'application (rôle <id>-editeur).
#
# Variables : NEXUS_USER, NEXUS_PASSWORD (secret), APP_ID, COMPONENT, VERSION,
#             BUILD, COMMIT, COMMIT_DATE, IMAGE (image Docker locale),
#             APP_DIR (répertoire Node.js, pour le SBOM)
# Garantie : image + SBOM + manifeste sont publiés ensemble, sinon rien ne reste.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

require APP_ID COMPONENT VERSION BUILD COMMIT COMMIT_DATE IMAGE APP_DIR
require_tools docker jq curl shasum
init_auth

CAND_TAG="${VERSION}-${BUILD}"
CAND_IMAGE="${NEXUS_DOCKER_CANDIDAT}/${APP_ID}/${COMPONENT}:${CAND_TAG}"
RAW_DIR="$(raw_path "$APP_ID" "$COMPONENT" "$CAND_TAG" "")"
RAW_DIR="${RAW_DIR%/}"
WORK="$(mktemp -d)"
UPLOADED=()
cleanup_partial() {
  local rc=$?
  if [ "$rc" -ne 0 ] && [ "${#UPLOADED[@]}" -gt 0 ]; then
    log "échec : retrait des fichiers déjà publiés (pas de publication partielle)"
    for f in "${UPLOADED[@]}"; do raw_delete raw-candidat "$f"; done
  fi
  rm -rf "$WORK"
  _cleanup_auth
  exit "$rc"
}
trap cleanup_partial EXIT

SBOM="${COMPONENT}-${VERSION}.cdx.json"
MANIFEST="${COMPONENT}-${VERSION}.manifest.json"

log "SBOM CycloneDX"
"$(dirname "$0")/gen-sbom.sh" "$APP_DIR" "$APP_ID" "$COMPONENT" "$VERSION" "$COMMIT" "$WORK/$SBOM"
log "SBOM généré : $WORK/$SBOM"
[ -f "$WORK/$SBOM" ] || die "SBOM manquant après gen-sbom.sh"

log "Image vers ${CAND_IMAGE}"
log "Authentification Nexus sur $NEXUS_DOCKER_CANDIDAT"
docker_login "$NEXUS_DOCKER_CANDIDAT" || die "docker login échoué"
log "Authentification OK"
docker tag "$IMAGE" "$CAND_IMAGE"
docker push -q "$CAND_IMAGE" >/dev/null
DIGEST="$(docker inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' "$CAND_IMAGE" \
  | grep "^${NEXUS_DOCKER_CANDIDAT}/" | head -1 | sed 's/.*@//')"
[ -n "$DIGEST" ] || die "empreinte de l'image introuvable après publication"

jq -n --arg app "$APP_ID" --arg comp "$COMPONENT" --arg ver "$VERSION" --arg build "$BUILD" \
  --arg commit "$COMMIT" --arg dc "$COMMIT_DATE" --arg digest "$DIGEST" \
  --arg sbom "$(sha256_of "$WORK/$SBOM")" '{
    application: $app, composant: $comp, version: $ver, build: $build,
    commit: $commit, dateCommit: $dc, origineSbom: "genere",
    empreinte: $digest, empreinteSbom: $sbom, imagesDorees: []
  }' > "$WORK/$MANIFEST"

# Le manifeste part en dernier : sa présence atteste que l'ensemble est complet.
log "Dépôt du SBOM et du manifeste dans raw-candidat/${RAW_DIR}"
raw_put raw-candidat "${RAW_DIR}/${SBOM}" "$WORK/$SBOM"
UPLOADED+=("${RAW_DIR}/${SBOM}")
raw_put raw-candidat "${RAW_DIR}/${MANIFEST}" "$WORK/$MANIFEST"
UPLOADED+=("${RAW_DIR}/${MANIFEST}")

log "Candidat publié : ${CAND_IMAGE} (${DIGEST})"
echo "candidate_tag=${CAND_TAG}"
echo "digest=${DIGEST}"
