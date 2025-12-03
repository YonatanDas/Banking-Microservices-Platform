#!/usr/bin/env bash
# Resolve service path by finding service.yaml in applications/ directories
# Usage: .github/scripts/applications/initialize-service-directory.sh <service_name>
# Sets: SERVICE_DIR environment variable for GitHub Actions

set -euo pipefail

SERVICE="${1:-}"

if [[ -z "${SERVICE}" ]]; then
  echo "Usage: $0 <service_name>" >&2
  exit 1
fi

# Look for service.yaml in applications/<service> directory
SERVICE_DIR="applications/${SERVICE}"

if [[ ! -d "${SERVICE_DIR}" ]]; then
  echo "Error: Service directory not found: ${SERVICE_DIR}" >&2
  exit 1
fi

# Verify service.yaml exists
if [[ ! -f "${SERVICE_DIR}/service.yaml" ]]; then
  echo "Error: service.yaml not found in ${SERVICE_DIR}" >&2
  exit 1
fi

# Set GitHub Actions environment variable
echo "SERVICE_DIR=./${SERVICE_DIR}" >> "$GITHUB_ENV"
echo "✅ Resolved service directory: ${SERVICE_DIR}"
