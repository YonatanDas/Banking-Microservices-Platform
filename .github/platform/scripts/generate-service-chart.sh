#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

SERVICE_NAME="${1:-}"
if [ -z "$SERVICE_NAME" ]; then
  echo "Usage: $0 <service-name>" >&2
  exit 1
fi

SERVICE_DIR="$ROOT_DIR/applications/$SERVICE_NAME"
CHART_DIR="$ROOT_DIR/helm/bankingapp-services/$SERVICE_NAME"

if [ ! -d "$SERVICE_DIR" ]; then
  echo "Service directory not found: $SERVICE_DIR" >&2
  exit 1
fi

if [ -d "$CHART_DIR" ]; then
  echo "Chart already exists for $SERVICE_NAME at $CHART_DIR, skipping generation."
  exit 0
fi

mkdir -p "$CHART_DIR/templates"

cat > "$CHART_DIR/Chart.yaml" <<EOF
apiVersion: v2
name: ${SERVICE_NAME}
description: Helm chart for ${SERVICE_NAME} service (generated)
type: application
version: 0.1.0
appVersion: "1.0.0"

dependencies:
  - name: bankingapp-common
    version: 0.1.0
    repository: "file://../../bankingapp-common"
EOF

cat > "$CHART_DIR/templates/include-common.yaml" <<'EOF'
{{ include "common.deployment" . }}

---

{{ include "common.service" . }}

---

{{ include "common.serviceaccount" . }}

---

{{ include "common.networkpolicy" . }}

---

{{ include "common.hpa" . }}

---

{{ include "common.denyAllIngress" . }}

---

{{ include "common.denyAllEgress" . }}

---

{{- include "common.servicemonitor" . }}

---

{{ include "common.poddisruptionbudget" . }}
EOF

# Generate values.yaml from service.yaml
"$ROOT_DIR/.github/platform/scripts/service-yaml-to-values.sh" "$SERVICE_NAME"

# Optional: helm lint/template if helm is installed
if command -v helm >/dev/null 2>&1; then
  helm lint "$CHART_DIR"
  helm template "$SERVICE_NAME" "$CHART_DIR" >/dev/null
fi

echo "Generated chart for $SERVICE_NAME in $CHART_DIR"


