#!/usr/bin/env bash
# Flux 1 : tout commit feat/fix cite l'identifiant d'une exigence qui existe dans Docs/exigences/
# (ex. « ACC-04 » dans le message), ou déclare le trailer « Exigence: non-applicable ».
# La règle s'applique aux commits postérieurs à celui de scripts/req/depuis.
#
# Usage : check-req.sh <base> [tête]     Code de sortie 1 si au moins un commit n'est pas couvert.
set -euo pipefail

BASE="${1:?usage : check-req.sh <base> [tête]}"
TETE="${2:-HEAD}"
HERE="$(cd "$(dirname "$0")" && pwd)"
DEPUIS="$(tr -d '[:space:]' < "$HERE/depuis")"

if [[ "$BASE" =~ ^0+$ ]]; then BASE="${TETE}~1"; fi
git rev-parse --verify --quiet "${BASE}^{commit}" >/dev/null || { echo "base introuvable : ${BASE}" >&2; exit 1; }

connues="$(grep -rhoE '^### [A-Z]{3,4}-[0-9]{2} ' Docs/exigences/*.md | awk '{print $2}' | sort -u)"
manquants=0
total=0
while read -r sha; do
  [[ -n "$sha" ]] || continue
  if git merge-base --is-ancestor "$sha" "$DEPUIS" 2>/dev/null; then continue; fi
  msg="$(git log -1 --format=%B "$sha")"
  sujet="${msg%%$'\n'*}"
  [[ "$sujet" =~ ^(feat|fix)(\(.*\))?!?: ]] || continue
  total=$((total + 1))
  if grep -Eq '^Exigence: non-applicable\s*$' <<<"$msg"; then continue; fi
  ok=0
  for id in $(grep -oE '\b[A-Z]{3,4}-[0-9]{2}\b' <<<"$msg" | sort -u); do
    if grep -qx "$id" <<<"$connues"; then ok=1; break; fi
  done
  if [[ "$ok" -eq 0 ]]; then
    echo "exigence manquante : ${sha:0:7} ${sujet}" >&2
    manquants=$((manquants + 1))
  fi
done < <(git rev-list --no-merges "${BASE}..${TETE}")

if [[ "$manquants" -gt 0 ]]; then
  echo "${manquants} commit(s) sur ${total} sans exigence (citer ACC-04, etc., ou « Exigence: non-applicable »)" >&2
  exit 1
fi
echo "exigences : ${total} commit(s) feat/fix contrôlé(s), tous rattachés"
