#!/usr/bin/env bash
# Get service configuration from service.yaml file
# Usage: .github/scripts/00-get-service-config.sh <service_name> <config_key>
# Example: .github/scripts/00-get-service-config.sh accounts path
# Config keys: path, helm_name, dockerfile, service_account_name, port

set -euo pipefail

SERVICE="${1:-}"
CONFIG_KEY="${2:-}"

if [[ -z "${SERVICE}" || -z "${CONFIG_KEY}" ]]; then
  echo "Usage: $0 <service_name> <config_key>" >&2
  echo "Config keys: path, helm_name, dockerfile, service_account_name, port" >&2
  exit 1
fi

SERVICE_DIR="services/${SERVICE}"
SERVICE_YAML="${SERVICE_DIR}/service.yaml"

# Check if service.yaml exists
if [[ ! -f "${SERVICE_YAML}" ]]; then
  echo "Error: ${SERVICE_YAML} not found" >&2
  exit 1
fi

# Use yq to extract values from service.yaml
if ! command -v yq &> /dev/null; then
  echo "Error: yq is required but not installed" >&2
  exit 1
fi

# Map config keys to service.yaml paths
case "${CONFIG_KEY}" in
  path)
    echo "services/${SERVICE}"
    ;;
  helm_name)
    # Use metadata.name from service.yaml
    yq eval ".metadata.name" "${SERVICE_YAML}" 2>/dev/null || echo "${SERVICE}"
    ;;
  dockerfile)
    # Default to Dockerfile, check if it exists
    if [[ -f "${SERVICE_DIR}/Dockerfile" ]]; then
      echo "Dockerfile"
    else
      echo "Dockerfile"  # Default even if not found
    fi
    ;;
  service_account_name)
    # Get from serviceAccount.name, fallback to <service>-sa
    yq eval ".serviceAccount.name" "${SERVICE_YAML}" 2>/dev/null || echo "${SERVICE}-sa"
    ;;
  port)
    # Get from container.port
    yq eval ".container.port" "${SERVICE_YAML}" 2>/dev/null || echo ""
    ;;
  *)
    echo "Error: Unknown config key: ${CONFIG_KEY}" >&2
    echo "Valid keys: path, helm_name, dockerfile, service_account_name, port" >&2
    exit 1
    ;;
esac
