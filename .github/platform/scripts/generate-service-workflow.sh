#!/usr/bin/env bash
set -euo pipefail

# Generate GitHub Actions workflow for a service
# Usage: generate-service-workflow.sh <service-name>

SERVICE_NAME="${1:-}"
if [ -z "$SERVICE_NAME" ]; then
  echo "Usage: $0 <service-name>" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

WORKFLOW_DIR=".github/workflows"
WORKFLOW_FILE="$WORKFLOW_DIR/applications-${SERVICE_NAME}.yaml"

# Check if workflow already exists
if [ -f "$WORKFLOW_FILE" ]; then
  echo "⚠️  Workflow already exists: $WORKFLOW_FILE, skipping"
  exit 0
fi

# Capitalize first letter for display name
SERVICE_DISPLAY=$(echo "$SERVICE_NAME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')

# Find a template workflow (use accounts as default)
TEMPLATE_WORKFLOW="$WORKFLOW_DIR/applications-accounts.yaml"

if [ ! -f "$TEMPLATE_WORKFLOW" ]; then
  echo "❌ Template workflow not found: $TEMPLATE_WORKFLOW" >&2
  exit 1
fi

# Copy template and replace service-specific values
sed \
  -e "s/accounts/${SERVICE_NAME}/g" \
  -e "s/Accounts/${SERVICE_DISPLAY}/g" \
  -e "s/Accounts-CI/${SERVICE_DISPLAY}-CI/g" \
  "$TEMPLATE_WORKFLOW" > "$WORKFLOW_FILE"

echo "✅ Generated workflow: $WORKFLOW_FILE"

