#!/usr/bin/env bash
set -euo pipefail

# Check for new services (services without workflow files)
# Usage: check-for-new-services.sh
# Outputs: has_new_services and new_services to GITHUB_OUTPUT

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

echo "🔍 Checking for new services..."

# Install jq if not available
if ! command -v jq >/dev/null 2>&1; then
  sudo apt-get update && sudo apt-get install -y jq
fi

# Get all service directories
NEW_SERVICES_ARRAY=()
HAS_NEW=false

for SERVICE_DIR in applications/*/; do
  if [ -d "$SERVICE_DIR" ]; then
    SERVICE=$(basename "$SERVICE_DIR")
    WORKFLOW_FILE=".github/workflows/applications-${SERVICE}.yaml"
    
    # Check if workflow exists
    if [ ! -f "$WORKFLOW_FILE" ]; then
      echo "🆕 New service detected: $SERVICE"
      NEW_SERVICES_ARRAY+=("$SERVICE")
      HAS_NEW=true
    fi
  fi
done

if [ "$HAS_NEW" = "true" ]; then
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "has_new_services=true" >> "$GITHUB_OUTPUT"
    # Convert array to JSON array directly
    NEW_JSON=$(printf '%s\n' "${NEW_SERVICES_ARRAY[@]}" | jq -R . | jq -s .)
    # Use delimiter format for multiline/special characters to avoid quoting issues
    {
      echo "new_services<<EOF"
      echo "$NEW_JSON"
      echo "EOF"
    } >> "$GITHUB_OUTPUT"
  fi
  NEW_SERVICES_STR=$(IFS=' '; echo "${NEW_SERVICES_ARRAY[*]}")
  echo "✅ Found new services: $NEW_SERVICES_STR"
else
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "has_new_services=false" >> "$GITHUB_OUTPUT"
    echo "new_services=[]" >> "$GITHUB_OUTPUT"
  fi
  echo "ℹ️  No new services detected. Existing services will use their own workflows."
fi

