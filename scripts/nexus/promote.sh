#!/usr/bin/env bash
# Promotion candidat vers release par republication contrôlée (spec 6.1, 6.3).
# Compte attendu : le compte de la chaîne de promotion (rôle promotion).
#
# Variables : NEXUS_USER, NEXUS_PASSWORD (secret), APP_ID, COMPONENT, VERSION,
#             BUILD, REPO_DIR (dépôt Git complet), PROTECTED_REFS (défaut : origin/main)
# Contrôles bloquants : manifeste et SBOM présents et complets (R2), commit sur une
# branche protégée (R3), empreinte de l'image conforme au manifeste, SBOM conforme.
# Hors périmètre de la maquette : analyse des licences et des vulnérabilités.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

require APP_ID COMPONENT VERSION BUILD REPO_DIR
require_tools docker jq curl shasum git
init_auth
PROTECTED_REFS="${PROTECTED_REFS:-origin/main}"

CAND_TAG="${VERSION}-${BUILD}"
CAND_DIR="$(raw_path "$APP_ID" "$COMPONENT" "$CAND_TAG" "")"; CAND_DIR="${CAND_DIR%/}"
REL_DIR="$(raw_path "$APP_ID" "$COMPONENT" "$VERSION" "")"; REL_DIR="${REL_DIR%/}"
SBOM="${COMPONENT}-${VERSION}.cdx.json"
MANIFEST="${COMPONENT}-${VERSION}.manifest.json"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"; _cleanup_auth' EXIT

# --- Contrôles --------------------------------------------------------------
raw_get raw-candidat "${CAND_DIR}/${MANIFEST}" "$WORK/$MANIFEST" || die "R2 : manifeste absent du candidat"
raw_get raw-candidat "${CAND_DIR}/${SBOM}" "$WORK/$SBOM" || die "R2 : SBOM absent du candidat"

jq -e --arg app "$APP_ID" --arg comp "$COMPONENT" --arg ver "$VERSION" --arg build "$BUILD" '
  .application == $app and .composant == $comp and .version == $ver and .build == $build
  and (.commit | type == "string" and length == 40) and (.dateCommit | type == "string" and length > 0)
  and (.origineSbom | IN("genere", "reconstitue")) and (.empreinte | startswith("sha256:"))
  and (.empreinteSbom | length == 64)' "$WORK/$MANIFEST" >/dev/null \
  || die "R2 : manifeste incomplet ou incohérent avec la demande"

jq -e '.bomFormat == "CycloneDX" and (.components | length > 0)' "$WORK/$SBOM" >/dev/null \
  || die "R2 : SBOM invalide ou vide"
[ "$(sha256_of "$WORK/$SBOM")" = "$(jq -r .empreinteSbom "$WORK/$MANIFEST")" ] \
  || die "SBOM modifié depuis la publication (empreinte différente)"

COMMIT="$(jq -r .commit "$WORK/$MANIFEST")"
ok=0
for ref in $PROTECTED_REFS; do
  if git -C "$REPO_DIR" merge-base --is-ancestor "$COMMIT" "$ref" 2>/dev/null; then ok=1; break; fi
done
[ "$ok" -eq 1 ] || die "R3 : le commit ${COMMIT} n'est pas sur une référence protégée (${PROTECTED_REFS})"

DIGEST="$(jq -r .empreinte "$WORK/$MANIFEST")"
CAND_IMAGE="${NEXUS_DOCKER_CANDIDAT}/${APP_ID}/${COMPONENT}"
REL_IMAGE="${NEXUS_DOCKER_RELEASE}/${APP_ID}/${COMPONENT}:${VERSION}"

# --- Idempotence : une release identique n'est pas une erreur ---------------
if raw_exists raw-release "${REL_DIR}/${MANIFEST}"; then
  raw_get raw-release "${REL_DIR}/${MANIFEST}" "$WORK/release.manifest.json"
  if [ "$(jq -r .empreinte "$WORK/release.manifest.json")" = "$DIGEST" ]; then
    log "Déjà promu à l'identique : ${REL_IMAGE}"
    echo "release=${REL_IMAGE}"; echo "digest=${DIGEST}"
    exit 0
  fi
  die "R1 : la release ${VERSION} existe avec un contenu différent ; publier une nouvelle version"
fi

# --- Republication contrôlée ------------------------------------------------
docker_login "$NEXUS_DOCKER_CANDIDAT"
docker pull -q "${CAND_IMAGE}@${DIGEST}" >/dev/null || die "image candidate introuvable : ${CAND_IMAGE}@${DIGEST}"
docker_login "$NEXUS_DOCKER_RELEASE"
docker tag "${CAND_IMAGE}@${DIGEST}" "$REL_IMAGE"
docker push -q "$REL_IMAGE" >/dev/null || die "R1 : publication en release refusée"
REL_DIGEST="$(docker inspect --format '{{range .RepoDigests}}{{println .}}{{end}}' "$REL_IMAGE" \
  | grep "^${NEXUS_DOCKER_RELEASE}/" | head -1 | sed 's/.*@//')"
[ "$REL_DIGEST" = "$DIGEST" ] || die "empreinte de la release (${REL_DIGEST}) différente du candidat (${DIGEST})"

raw_put raw-release "${REL_DIR}/${SBOM}" "$WORK/$SBOM"
raw_put raw-release "${REL_DIR}/${MANIFEST}" "$WORK/$MANIFEST"

log "Promu : ${REL_IMAGE} (${DIGEST})"
echo "release=${REL_IMAGE}"
echo "digest=${DIGEST}"
