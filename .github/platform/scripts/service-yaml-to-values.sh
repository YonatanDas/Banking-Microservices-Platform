#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

SERVICE_NAME="${1:-}"
if [ -z "$SERVICE_NAME" ]; then
  echo "Usage: $0 <service-name> [output-values.yaml]" >&2
  exit 1
fi

SERVICE_YAML="$ROOT_DIR/applications/$SERVICE_NAME/service.yaml"
if [ ! -f "$SERVICE_YAML" ]; then
  echo "service.yaml not found for $SERVICE_NAME at $SERVICE_YAML" >&2
  exit 1
fi

OUTPUT_VALUES="${2:-$ROOT_DIR/helm/bankingapp-services/$SERVICE_NAME/values.yaml}"

if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required" >&2
  exit 1
fi

# Build values.yaml expected by bankingapp-common templates
yq eval -n "
  (.deploymentName = \"${SERVICE_NAME}-deployment\") |
  (.serviceName = \"${SERVICE_NAME}\") |
  (.appLabel = \"${SERVICE_NAME}\") |
  (.appName = \"${SERVICE_NAME}\") |
  (.containerPort = (.container.port // 8080)) |
  (.servicePort = (.service.port // .container.port // 8080)) |
  (.replicaCount = (.replicas.default // 1)) |
  (.resources = (.resources // {})) |
  (.probes = (.probes // {})) |
  (.service = (.service // {})) |
  (.hpa = (.hpa // {})) |
  (.networkpolicy = (.networkPolicy // {})) |
  (.monitoring = (.monitoring // {})) |
  (.secretName = (.environment.secrets[0].name // \"\")) |
  (.env = (.environment.variables // []))
" "$SERVICE_YAML" > "$OUTPUT_VALUES"

echo "Generated values.yaml for $SERVICE_NAME at $OUTPUT_VALUES"


