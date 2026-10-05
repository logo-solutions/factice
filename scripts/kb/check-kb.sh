#!/usr/bin/env bash
# Contrôle de la base de connaissances : tout commit « fix » doit capitaliser dans Docs/kb.md,
# soit en modifiant ce fichier, soit en déclarant un trailer « KB: KB-NNN » (fiche existante)
# ou « KB: non-applicable » (avec la raison dans le message).
#
# Usage : check-kb.sh <base> [tête]     (tête : HEAD par défaut)
# Code de sortie 1 si au moins un commit fix n'est pas couvert.
set -euo pipefail

BASE="${1:?usage : check-kb.sh <base> [tête]}"
TETE="${2:-HEAD}"
KB="Docs/kb.md"

# Première publication d'une branche : l'ancienne tête est nulle, on ne contrôle que le dernier commit.
if [[ "$BASE" =~ ^0+$ ]]; then BASE="${TETE}~1"; fi
git rev-parse --verify --quiet "${BASE}^{commit}" >/dev/null || { echo "base introuvable : ${BASE}" >&2; exit 1; }

manquants=0
total=0
while read -r sha; do
  [[ -n "$sha" ]] || continue
  sujet="$(git log -1 --format=%s "$sha")"
  [[ "$sujet" =~ ^(fix|hotfix)(\(.*\))?!?: ]] || continue
  total=$((total + 1))
  if git show --name-only --format= "$sha" | grep -qx "$KB"; then continue; fi
  if git log -1 --format=%B "$sha" | grep -Eq '^KB: (KB-[0-9]{3}|non-applicable)\s*$'; then continue; fi
  echo "KB manquante : ${sha:0:7} ${sujet}" >&2
  manquants=$((manquants + 1))
done < <(git rev-list --no-merges "${BASE}..${TETE}")

if [[ "$manquants" -gt 0 ]]; then
  echo "${manquants} commit(s) fix sur ${total} sans fiche dans ${KB} (ajouter une fiche KB-NNN ou un trailer « KB: non-applicable »)" >&2
  exit 1
fi
echo "base de connaissances : ${total} commit(s) fix contrôlé(s), tous couverts"
