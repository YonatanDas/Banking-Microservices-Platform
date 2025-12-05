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
NEW_SERVICES=""
HAS_NEW=false

for SERVICE_DIR in applications/*/; do
  if [ -d "$SERVICE_DIR" ]; then
    SERVICE=$(basename "$SERVICE_DIR")
    WORKFLOW_FILE=".github/workflows/applications-${SERVICE}.yaml"
    
    # Check if workflow exists
    if [ ! -f "$WORKFLOW_FILE" ]; then
      echo "🆕 New service detected: $SERVICE"
      NEW_SERVICES="${NEW_SERVICES}${SERVICE} "
      HAS_NEW=true
    fi
  fi
done

if [ "$HAS_NEW" = "true" ]; then
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "has_new_services=true" >> "$GITHUB_OUTPUT"
    # Output as JSON array for matrix
    NEW_JSON=$(echo "$NEW_SERVICES" | tr ' ' '\n' | grep -v '^$' | jq -R . | jq -s .)
    echo "new_services=$NEW_JSON" >> "$GITHUB_OUTPUT"
  fi
  echo "✅ Found new services: $NEW_SERVICES"
else
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "has_new_services=false" >> "$GITHUB_OUTPUT"
    echo "new_services=[]" >> "$GITHUB_OUTPUT"
  fi
  echo "ℹ️  No new services detected. Existing services will use their own workflows."
fi

