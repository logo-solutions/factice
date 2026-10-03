#!/usr/bin/env bash
# Recette Nexus (spec 11) : R1, R2, R3, R4, R8, R11 et cloisonnement des comptes.
# R5 (quarantaine), R7 et R9 (CMDB), R10 (restauration) dépendent de composants
# absents de la maquette : elles restent à la charge de l'exploitation.
#
# Variables : NEXUS_URL, NEXUS_DOCKER_CANDIDAT, NEXUS_DOCKER_RELEASE,
#             SECRETS_DIR (défaut : .secrets/nexus), REPO_DIR, IMAGE (image locale)
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SECRETS_DIR="${SECRETS_DIR:-$HERE/../../.secrets/nexus}"
REPO_DIR="${REPO_DIR:-$HERE/../..}"
export NEXUS_URL="${NEXUS_URL:-http://localhost:8081}"
export NEXUS_DOCKER_CANDIDAT="${NEXUS_DOCKER_CANDIDAT:-localhost:5001}"
export NEXUS_DOCKER_RELEASE="${NEXUS_DOCKER_RELEASE:-localhost:5002}"
: "${IMAGE:?IMAGE (image Docker locale à publier) est obligatoire}"
BUILD="${BUILD:-$(date +%s)}"
export APP_ID=factice.app COMPONENT=factice VERSION="${VERSION:-0.0.$BUILD}" BUILD REPO_DIR IMAGE
export APP_DIR="${APP_DIR:-$REPO_DIR/app}"
COMMIT="$(git -C "$REPO_DIR" rev-parse HEAD)"; export COMMIT
COMMIT_DATE="$(git -C "$REPO_DIR" log -1 --format=%cI)"; export COMMIT_DATE

pw() { cat "$SECRETS_DIR/$1"; }
as() { local u="$1"; shift; NEXUS_USER="$u" NEXUS_PASSWORD="$(pw "$u")" "$@"; }
http() { curl -s -o /dev/null -w '%{http_code}' "$@"; }

FAIL=0
check() {  # check <réf> <libellé> <0|1 : réussi>
  if [ "$3" -eq 0 ]; then printf 'PASS %s %s\n' "$1" "$2"; else printf 'FAIL %s %s\n' "$1" "$2"; FAIL=1; fi
}
quiet() { "$@" >/dev/null 2>&1; }

BUILDER=svc-build-factice-app
PROMO=svc-promotion

as $BUILDER "$HERE/publish-candidate.sh" >/dev/null 2>&1; check cycle "publication en candidat" $?

# R2 : candidat sans manifeste
BUILD=$((BUILD + 1000000)) as $PROMO "$HERE/promote.sh" >/dev/null 2>&1; r=$?
[ $r -ne 0 ]; check R2 "promotion d'un candidat incomplet refusée" $?

# R3 : commit absent d'une référence protégée
PROTECTED_REFS=origin/inexistante as $PROMO "$HERE/promote.sh" >/dev/null 2>&1
[ $? -ne 0 ]; check R3 "promotion d'un commit hors branche protégée refusée" $?

as $PROMO "$HERE/promote.sh" >/dev/null 2>&1; check cycle "promotion en release" $?

# R1 : republication sur une release existante
printf '%s' "$(pw $PROMO)" | docker login "$NEXUS_DOCKER_RELEASE" -u $PROMO --password-stdin >/dev/null 2>&1
docker tag "$IMAGE" "$NEXUS_DOCKER_RELEASE/$APP_ID/$COMPONENT:$VERSION"
docker push -q "$NEXUS_DOCKER_RELEASE/$APP_ID/$COMPONENT:$VERSION" >/dev/null 2>&1
rc=$?
# Même contenu : Nexus peut l'accepter sans réécrire ; on exige donc un contenu différent.
docker build -q -t "$IMAGE-r1" --label r1="$BUILD" -f - "$APP_DIR" >/dev/null 2>&1 <<'D'
FROM scratch
LABEL r1=1
D
docker tag "$IMAGE-r1" "$NEXUS_DOCKER_RELEASE/$APP_ID/$COMPONENT:$VERSION"
quiet docker push -q "$NEXUS_DOCKER_RELEASE/$APP_ID/$COMPONENT:$VERSION"; [ $? -ne 0 ]; check R1 "republication sur une release refusée" $?
raw_status=$(http -u "$PROMO:$(pw $PROMO)" --data x -X PUT "$NEXUS_URL/repository/raw-release/$APP_ID/$COMPONENT/$VERSION/$COMPONENT-$VERSION.manifest.json")
[ "$raw_status" = 409 ]; check R1 "réécriture d'un manifeste de release refusée (HTTP $raw_status)" $?

# R4 : un éditeur ne publie que sous son préfixe
echo x > /tmp/recette-r4.txt
s=$(http -u "$BUILDER:$(pw $BUILDER)" --upload-file /tmp/recette-r4.txt "$NEXUS_URL/repository/raw-candidat/mutualise/intrus/1/x.txt")
[ "$s" = 403 ]; check R4 "publication hors préfixe refusée (HTTP $s)" $?
s=$(http -u "$BUILDER:$(pw $BUILDER)" --upload-file /tmp/recette-r4.txt "$NEXUS_URL/repository/raw-release/$APP_ID/intrus/1/x.txt")
[ "$s" = 403 ]; check R4 "éditeur sans droit d'écriture en release (HTTP $s)" $?
s=$(http -u "svc-build-mutualise:$(pw svc-build-mutualise)" --upload-file /tmp/recette-r4.txt "$NEXUS_URL/repository/raw-candidat/$APP_ID/intrus/1/x.txt")
[ "$s" = 403 ]; check R4 "éditeur d'une autre application refusé (HTTP $s)" $?
rm -f /tmp/recette-r4.txt

# Compte de déploiement : lecture seule
s=$(http -u "svc-deploiement:$(pw svc-deploiement)" "$NEXUS_URL/repository/raw-release/$APP_ID/$COMPONENT/$VERSION/$COMPONENT-$VERSION.manifest.json")
[ "$s" = 200 ]; check cloisonnement "déploiement lit la release (HTTP $s)" $?
s=$(http -u "svc-deploiement:$(pw svc-deploiement)" -X PUT --data x "$NEXUS_URL/repository/raw-release/$APP_ID/intrus/x.txt")
[ "$s" = 403 ]; check cloisonnement "déploiement n'écrit pas en release (HTTP $s)" $?

# R8 : retrouver les artefacts d'une application par son identifiant
# L'index de recherche est asynchrone : on laisse jusqu'à 90 s pour l'indexation.
for _ in 1 2 3 4 5 6 7 8 9; do
  n=$(curl -s -u "svc-promotion:$(pw svc-promotion)" "$NEXUS_URL/service/rest/v1/search/assets?repository=raw-release&q=$APP_ID" | jq --arg p "/$APP_ID/" '[.items[] | select(.path | startswith($p))] | length')
  [ "${n:-0}" -ge 2 ] && break
  sleep 10
done
[ "${n:-0}" -ge 2 ]; check R8 "recherche par identifiant d'application (${n:-0} assets en release)" $?

# R11 : accès anonyme refusé
s=$(http "$NEXUS_URL/repository/raw-release/$APP_ID/$COMPONENT/$VERSION/$COMPONENT-$VERSION.manifest.json")
[ "$s" = 401 ] || [ "$s" = 403 ]; check R11 "lecture anonyme refusée (HTTP $s)" $?

exit $FAIL
