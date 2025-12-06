#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

SERVICE_NAME="${1:-}"
if [ -z "$SERVICE_NAME" ]; then
  echo "Usage: $0 <service-name>" >&2
  exit 1
fi

if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required" >&2
  exit 1
fi

for ENV in dev-env stag-env prod-env; do
  CHART="$ROOT_DIR/helm/environments/$ENV/Chart.yaml"

  if [ ! -f "$CHART" ]; then
    echo "[$ENV] Chart.yaml not found at $CHART, skipping."
    continue
  fi

  # Check if dependency already exists
  if yq eval ".dependencies[]?.name == \"$SERVICE_NAME\"" "$CHART" | grep -q "true"; then
    echo "[$ENV] dependency for $SERVICE_NAME already present, skipping."
    continue
  fi

  echo "[$ENV] adding dependency for $SERVICE_NAME"

  yq eval "
    .dependencies += [{
      \"name\": \"$SERVICE_NAME\",
      \"version\": \"0.1.0\",
      \"repository\": \"file://../../bankingapp-services/$SERVICE_NAME\"
    }]
  " -i "$CHART"
done


