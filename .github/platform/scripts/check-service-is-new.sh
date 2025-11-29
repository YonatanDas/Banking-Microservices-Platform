#!/usr/bin/env bash
set -euo pipefail

# Check if a service is new (Helm chart doesn't exist) and output result to GITHUB_OUTPUT
# Usage: .github/platform/scripts/check-service-is-new.sh <service-name>
# Outputs: is_new=true or is_new=false to GITHUB_OUTPUT

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

SERVICE_NAME="${1:-}"
if [ -z "$SERVICE_NAME" ]; then
  echo "Usage: $0 <service-name>" >&2
  exit 1
fi

CHART_DIR="$ROOT_DIR/06-helm/bankingapp-services/$SERVICE_NAME"

if [ ! -d "$CHART_DIR" ]; then
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "is_new=true" >> "${GITHUB_OUTPUT}"
  fi
  echo "🆕 New service detected: $SERVICE_NAME"
  echo "   Will generate Helm chart and update environment dependencies."
else
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "is_new=false" >> "${GITHUB_OUTPUT}"
  fi
  echo "✅ Existing service: $SERVICE_NAME"
  echo "   Chart already exists, skipping chart generation."
fi

