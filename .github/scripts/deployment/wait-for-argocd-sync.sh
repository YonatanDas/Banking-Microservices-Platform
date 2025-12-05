#!/usr/bin/env bash
set -euo pipefail

# Usage: wait-for-argocd-sync.sh <SERVICE> <ENVIRONMENT> [TIMEOUT_SECONDS] [ARGOCD_URL]
# Waits for ArgoCD application to sync and be healthy (reads from .deployment-config.yaml)

SERVICE="${1}"
ENVIRONMENT="${2}"
TIMEOUT="${3:-}"
ARGOCD_URL="${4:-}"

if [[ -z "${SERVICE}" || -z "${ENVIRONMENT}" ]]; then
  echo "❌ Usage: $0 <SERVICE> <ENVIRONMENT> [TIMEOUT_SECONDS] [ARGOCD_URL]" >&2
  exit 1
fi

# Install yq if not available
if ! command -v yq &> /dev/null; then
  wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
  chmod +x /usr/local/bin/yq
fi

CONFIG_FILE=".github/workflows/.deployment-config.yaml"

# Get ArgoCD config from file if available
if [[ -f "${CONFIG_FILE}" ]]; then
  ARGOCD_NAMESPACE=$(yq eval ".argocd.namespace // \"argocd\"" "${CONFIG_FILE}" 2>/dev/null || echo "argocd")
  
  # Get timeout from config if not provided
  if [[ -z "${TIMEOUT}" ]]; then
    TIMEOUT=$(yq eval ".argocd.sync_timeout // 300" "${CONFIG_FILE}" 2>/dev/null || echo "300")
  fi
else
  ARGOCD_NAMESPACE="argocd"
  TIMEOUT="${TIMEOUT:-300}"
fi

# Install kubectl if not available
if ! command -v kubectl &> /dev/null; then
  echo "📦 Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  mv kubectl /usr/local/bin/
fi

# Install jq if not available
if ! command -v jq &> /dev/null; then
  echo "📦 Installing jq..."
  wget -qO /usr/local/bin/jq https://github.com/jqlang/jq/releases/latest/download/jq-linux-amd64
  chmod +x /usr/local/bin/jq
fi

# Determine ArgoCD application name
# Format: {service}-{environment} or just {service}
APP_NAME="${SERVICE}"
if [[ -n "${ENVIRONMENT}" && "${ENVIRONMENT}" != "dev" ]]; then
  APP_NAME="${SERVICE}-${ENVIRONMENT}"
fi

echo "🔄 Waiting for ArgoCD application '${APP_NAME}' to sync..."
echo "   Timeout: ${TIMEOUT} seconds"

# Function to check ArgoCD sync status via kubectl
check_argocd_status() {
  # Try to get application status from ArgoCD
  # First, try via kubectl (if ArgoCD is accessible)
  if kubectl get application "${APP_NAME}" -n "${ARGOCD_NAMESPACE}" -o json 2>/dev/null | jq -e '.status.sync.status == "Synced" and .status.health.status == "Healthy"' > /dev/null 2>&1; then
    return 0
  fi
  
  # If kubectl fails, try ArgoCD API (if URL provided)
  if [[ -n "${ARGOCD_URL}" ]]; then
    # This would require ArgoCD token - placeholder for now
    # ARGOCD_TOKEN=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    # curl -s -k -H "Authorization: Bearer ${ARGOCD_TOKEN}" "${ARGOCD_URL}/api/v1/applications/${APP_NAME}" | jq -e '.status.sync.status == "Synced" and .status.health.status == "Healthy"' > /dev/null 2>&1
    return 1
  fi
  
  return 1
}

# Wait for sync with timeout
ELAPSED=0
INTERVAL=10

while [[ ${ELAPSED} -lt ${TIMEOUT} ]]; do
  if check_argocd_status; then
    echo "✅ ArgoCD application '${APP_NAME}' is synced and healthy"
    
    # Get detailed status
    if kubectl get application "${APP_NAME}" -n "${ARGOCD_NAMESPACE}" -o json 2>/dev/null > /tmp/argocd-status.json; then
      SYNC_STATUS=$(jq -r '.status.sync.status // "Unknown"' /tmp/argocd-status.json)
      HEALTH_STATUS=$(jq -r '.status.health.status // "Unknown"' /tmp/argocd-status.json)
      REVISION=$(jq -r '.status.sync.revision // "Unknown"' /tmp/argocd-status.json)
      
      echo "   Sync Status: ${SYNC_STATUS}"
      echo "   Health Status: ${HEALTH_STATUS}"
      echo "   Revision: ${REVISION}"
    fi
    
    exit 0
  fi
  
  echo "   Waiting... (${ELAPSED}/${TIMEOUT} seconds)"
  sleep ${INTERVAL}
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo "❌ ArgoCD sync timeout after ${TIMEOUT} seconds" >&2
echo "⚠️  Application '${APP_NAME}' may not be synced or healthy" >&2

# Try to get current status
if kubectl get application "${APP_NAME}" -n "${ARGOCD_NAMESPACE}" -o json 2>/dev/null > /tmp/argocd-status.json; then
  SYNC_STATUS=$(jq -r '.status.sync.status // "Unknown"' /tmp/argocd-status.json)
  HEALTH_STATUS=$(jq -r '.status.health.status // "Unknown"' /tmp/argocd-status.json)
  SYNC_MESSAGE=$(jq -r '.status.conditions[]? | select(.type=="ComparisonError" or .type=="SyncError") | .message' /tmp/argocd-status.json || echo "No error message")
  
  echo "   Current Sync Status: ${SYNC_STATUS}"
  echo "   Current Health Status: ${HEALTH_STATUS}"
  if [[ -n "${SYNC_MESSAGE}" ]]; then
    echo "   Error: ${SYNC_MESSAGE}"
  fi
fi

exit 1

