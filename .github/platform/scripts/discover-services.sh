#!/usr/bin/env bash
set -euo pipefail

# Discover changed services and write a JSON array to the GitHub Actions output
# variable "changes". A service is detected if any file under services/<name>/ changed.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

# BASE_REF is passed from the workflow; default to main if empty
BASE_REF="${BASE_REF:-main}"

changed_files="$(git diff --name-only "origin/${BASE_REF}...HEAD" 2>/dev/null || git diff --name-only HEAD~1 2>/dev/null || echo "")"

echo "Changed files:"
echo "${changed_files}"

services="$(printf '%s\n' "${changed_files}" \
  | grep '^services/' || true \
  | cut -d'/' -f2 \
  | sort -u \
  | jq -R . \
  | jq -s -c .)"

if [ -z "${services}" ] || [ "${services}" = "[]" ]; then
  services="[]"
  any_changed="false"
else
  any_changed="true"
fi

echo "Detected services: ${services}"
echo "Any changed: ${any_changed}"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "changes<<EOF"
    echo "${services}"
    echo "EOF"
  } >> "${GITHUB_OUTPUT}"
  echo "any_changed=${any_changed}" >> "${GITHUB_OUTPUT}"
else
  echo "changes=${services}"
  echo "any_changed=${any_changed}"
fi


