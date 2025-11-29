#!/usr/bin/env bash
# Resolve service path and set GitHub Actions environment variable
# Usage: .github/scripts/00-resolve-service-path.sh <service_name>
# Sets: SERVICE_DIR environment variable for GitHub Actions

set -euo pipefail

SERVICE="${1:-}"

if [[ -z "${SERVICE}" ]]; then
  echo "Usage: $0 <service_name>" >&2
  exit 1
fi

# Get the service path from config
SERVICE_DIR=$(./.github/scripts/00-get-service-config.sh "${SERVICE}" path)

if [[ -z "${SERVICE_DIR}" ]]; then
  # Fallback: assume conventional layout services/<service>
  if [ -d "services/${SERVICE}" ]; then
    SERVICE_DIR="services/${SERVICE}"
    echo "ℹ️  ${SERVICE} not found in .github/config/services.yaml, using default path ${SERVICE_DIR}"
  else
    echo "Error: Could not find path for service ${SERVICE} in .github/config/services.yaml or services/${SERVICE}" >&2
    exit 1
  fi
fi

# Set GitHub Actions environment variable
echo "SERVICE_DIR=./${SERVICE_DIR}" >> "$GITHUB_ENV"
echo "✅ Resolved service directory: ${SERVICE_DIR}"
