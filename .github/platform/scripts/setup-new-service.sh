#!/usr/bin/env bash
set -euo pipefail

# Master script to set up a new service: Helm chart and workflow
# Usage: setup-new-service.sh <service-name>

SERVICE_NAME="${1:-}"
if [ -z "$SERVICE_NAME" ]; then
  echo "Usage: $0 <service-name>" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

echo "🚀 Setting up new service: $SERVICE_NAME"

# 1. Generate Helm chart
echo "📦 Generating Helm chart..."
.github/platform/scripts/generate-service-chart.sh "$SERVICE_NAME"

# 2. Update environment chart dependencies
echo "🔄 Updating environment chart dependencies..."
.github/platform/scripts/update-env-chart.sh "$SERVICE_NAME"

# 3. Generate GitHub Actions workflow
echo "⚙️  Generating GitHub Actions workflow..."
.github/platform/scripts/generate-service-workflow.sh "$SERVICE_NAME"

echo "✅ Service setup complete for $SERVICE_NAME"

