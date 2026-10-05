#!/usr/bin/env bash
# Flux 7 : notes de version générées à la promotion (Markdown sur stdout).
# Usage : notes.sh <version> <empreinte> <base> [tête]
#   base : commit de la version précédente (0000… ou vide : dernier commit seulement)
# Contenu : changements, exigences citées, fiches KB ajoutées (flux 13), preuves de tests (flux 6).
set -euo pipefail

VERSION="${1:?version}"
EMPREINTE="${2:?empreinte}"
BASE="${3:-}"
TETE="${4:-HEAD}"
PREUVES="${PREUVES:-preuves/preuves-exigences.md}"

if [[ -z "$BASE" || "$BASE" =~ ^0+$ ]] || ! git rev-parse --verify --quiet "${BASE}^{commit}" >/dev/null; then
  BASE="${TETE}~1"
fi

echo "# Notes de version factice ${VERSION}"
echo
echo "- Empreinte : \`${EMPREINTE}\`"
echo "- Commit : \`$(git rev-parse --short "$TETE")\`"
echo "- Période : \`$(git rev-parse --short "$BASE")..$(git rev-parse --short "$TETE")\`"
echo
echo "## Changements"
echo
git log --no-merges --format='- %s (`%h`)' "${BASE}..${TETE}"
echo
echo "## Exigences citées"
echo
ids="$(git log --no-merges --format=%B "${BASE}..${TETE}" | grep -oE '\b[A-Z]{3,4}-[0-9]{2}\b' | sort -u || true)"
if [[ -n "$ids" ]]; then sed 's/^/- /' <<<"$ids"; else echo "Aucune."; fi
echo
echo "## Fiches de la base de connaissances ajoutées"
echo
fiches="$(git diff --unified=0 "${BASE}..${TETE}" -- Docs/kb.md | sed -n 's/^+## \(KB-[0-9]*\) · \(.*\)$/- \1 : \2/p')"
if [[ -n "$fiches" ]]; then echo "$fiches"; else echo "Aucune."; fi
echo
echo "## Preuves de tests"
echo
if [[ -f "$PREUVES" ]]; then sed -n '3p' "$PREUVES"; echo; echo "Détail : artefact \`preuves-exigences\` du run."; else echo "Non générées."; fi
