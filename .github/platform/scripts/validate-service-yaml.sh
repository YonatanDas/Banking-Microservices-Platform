#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

SCHEMA="$ROOT_DIR/.github/platform/schemas/service-schema.json"

if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required" >&2
  exit 1
fi

if ! command -v ajv >/dev/null 2>&1; then
  echo "ajv-cli not found, skipping schema validation (install with: npm i -g ajv-cli)" >&2
  exit 0
fi

# Validate all service.yaml files or a specific one
FILES=("$@")
if [ ${#FILES[@]} -eq 0 ]; then
  # Default: all service.yaml under applications/
  while IFS= read -r f; do
    FILES+=("$f")
  done < <(find "$ROOT_DIR/applications" -maxdepth 2 -name "service.yaml")
fi

for f in "${FILES[@]}"; do
  if [ ! -f "$f" ]; then
    echo "Skipping missing file $f"
    continue
  fi

  echo "Validating $f"
  tmp_json="$(mktemp)"
  yq -o=json "$f" > "$tmp_json"
  ajv validate -s "$SCHEMA" -d "$tmp_json"
  rm -f "$tmp_json"
done

echo "All service.yaml files are valid."


