#!/usr/bin/env bash
set -euo pipefail

# Discover changed services and write a JSON array to the GitHub Actions output
# variable "changes". A service is detected if any file under services/<name>/ changed.
# Also validates that detected services actually exist in services/ directory.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

# Debug: Log environment and git state
echo "=== Service Discovery Debug Info ==="
echo "BASE_REF (from env): ${BASE_REF:-not set}"
echo "Git branch: $(git branch --show-current 2>/dev/null || echo 'detached HEAD')"
echo "Git HEAD: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
echo "Recent commits:"
git log --oneline -3 2>/dev/null || echo "  (no commits found)"
echo ""

# Improve BASE_REF logic for push events
if [ -z "${BASE_REF}" ] || [ "${BASE_REF}" = "" ]; then
  # For push events, try HEAD~1 first (most recent commit)
  if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
    BASE_REF="HEAD~1"
    echo "ℹ️  BASE_REF not set, using HEAD~1 for comparison"
  else
    BASE_REF="main"
    echo "ℹ️  BASE_REF not set and no HEAD~1, defaulting to main"
  fi
fi

# Try multiple diff strategies with better logging
changed_files=""
diff_strategy=""

if [ "${BASE_REF}" != "HEAD~1" ] && git rev-parse --verify "origin/${BASE_REF}" >/dev/null 2>&1; then
  changed_files="$(git diff --name-only "origin/${BASE_REF}...HEAD" 2>/dev/null || echo "")"
  if [ -n "${changed_files}" ]; then
    diff_strategy="origin/${BASE_REF}...HEAD"
    echo "✅ Using diff strategy: origin/${BASE_REF}...HEAD"
  fi
fi

if [ -z "${changed_files}" ] && git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
  changed_files="$(git diff --name-only HEAD~1 2>/dev/null || echo "")"
  if [ -n "${changed_files}" ]; then
    diff_strategy="HEAD~1"
    echo "✅ Falling back to diff strategy: HEAD~1"
  fi
fi

if [ -z "${changed_files}" ]; then
  changed_files=""
  echo "⚠️  Warning: No changes detected with any diff strategy"
  echo "   This may be normal if this is the first commit or if no files changed."
fi

echo ""
echo "=== Changed Files ==="
if [ -z "${changed_files}" ]; then
  echo "(none)"
else
  echo "${changed_files}"
fi
echo ""

# Extract service names from changed files
services_raw="$(printf '%s\n' "${changed_files}" \
  | grep '^services/' || true \
  | cut -d'/' -f2 \
  | sort -u)"

echo "=== Service Detection ==="
if [ -z "${services_raw}" ]; then
  echo "No services detected in changed files"
  services="[]"
  any_changed="false"
else
  echo "Raw service names detected:"
  echo "${services_raw}" | while read -r svc; do
    echo "  - ${svc}"
  done
  
  # Validate that detected services actually exist in services/ directory
  echo ""
  echo "Validating service directories exist:"
  valid_services=()
  invalid_services=()
  
  while IFS= read -r svc; do
    if [ -n "${svc}" ] && [ -d "services/${svc}" ]; then
      valid_services+=("${svc}")
      echo "  ✅ ${svc} - directory exists"
    else
      invalid_services+=("${svc}")
      echo "  ⚠️  ${svc} - directory NOT found (will be filtered out)"
    fi
  done <<< "${services_raw}"
  
  # Convert valid services to JSON array
  if [ ${#valid_services[@]} -eq 0 ]; then
    services="[]"
    any_changed="false"
    echo ""
    echo "⚠️  No valid service directories found. All detected services were filtered out."
  else
    services="$(printf '%s\n' "${valid_services[@]}" \
      | jq -R . \
      | jq -s -c .)"
    any_changed="true"
    echo ""
    echo "✅ Valid services: ${services}"
  fi
  
  # Warn about filtered services
  if [ ${#invalid_services[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  Warning: The following service names were detected but directories don't exist:"
    printf '  - %s\n' "${invalid_services[@]}"
    echo "   These will be excluded from the CI matrix."
  fi
fi

echo ""
echo "=== Final Output ==="
echo "Detected services (JSON): ${services}"
echo "Any changed: ${any_changed}"

# Write to GitHub Actions output
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

echo ""
echo "=== Service Discovery Complete ==="
