#!/usr/bin/env bash
# Génère le SBOM CycloneDX (JSON) d'une application Node.js (spec 6.5).
# Usage : gen-sbom.sh <répertoire app> <application> <composant> <version> <commit> <sortie>
set -euo pipefail
APP_DIR="$1"; APP_ID="$2"; COMPONENT="$3"; VERSION="$4"; COMMIT="$5"; OUT="$6"

(cd "$APP_DIR" && npm ls --all --omit=dev --long --json 2>/dev/null) | jq \
  --arg app "$APP_ID" --arg comp "$COMPONENT" --arg ver "$VERSION" --arg commit "$COMMIT" \
  --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg serial "urn:uuid:$(uuidgen | tr 'A-Z' 'a-z')" '
  def walk_deps: (.dependencies // {}) | to_entries[] | .value as $v | {name: .key, version: $v.version, license: $v.license}, ($v | walk_deps);
  {
    bomFormat: "CycloneDX", specVersion: "1.5", serialNumber: $serial, version: 1,
    metadata: {
      timestamp: $now,
      component: {type: "application", name: $comp, version: $ver, "bom-ref": ($app + "/" + $comp)},
      properties: [
        {name: "application", value: $app},
        {name: "commit", value: $commit},
        {name: "origineSbom", value: "genere"}
      ]
    },
    components: ([walk_deps] | unique_by(.name + "@" + .version) | map(select(.version != null) | {
      type: "library", name: .name, version: .version,
      purl: ("pkg:npm/" + .name + "@" + .version),
      licenses: (if .license then [{license: {id: (.license | tostring)}}] else [] end)
    }))
  }' > "$OUT"
jq -e '.components | length > 0' "$OUT" >/dev/null || { echo "SBOM vide : npm ci manquant ?" >&2; exit 1; }
