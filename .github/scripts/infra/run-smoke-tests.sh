#!/usr/bin/env bash
set -euo pipefail

# Usage: run-smoke-tests.sh <SERVICE> <NAMESPACE> [TIMEOUT_SECONDS]
# Runs smoke tests against deployed service using health endpoints

SERVICE="${1}"
NAMESPACE="${2:-default}"
TIMEOUT="${3:-60}"

if [[ -z "${SERVICE}" ]]; then
  echo "❌ Usage: $0 <SERVICE> <NAMESPACE> [TIMEOUT_SECONDS]" >&2
  exit 1
fi

# Service port mapping
declare -A SERVICE_PORTS=(
  ["accounts"]="8080"
  ["cards"]="9000"
  ["loans"]="8090"
  ["gateway"]="8072"
)

PORT="${SERVICE_PORTS[${SERVICE}]:-8080}"

echo "🧪 Running smoke tests for ${SERVICE}..."
echo "   Namespace: ${NAMESPACE}"
echo "   Port: ${PORT}"
echo "   Timeout: ${TIMEOUT} seconds"

# Get service endpoint
SERVICE_ENDPOINT="${SERVICE}.${NAMESPACE}.svc.cluster.local"
HEALTH_URL="http://${SERVICE_ENDPOINT}:${PORT}/actuator/health"

echo "🔍 Testing health endpoint: ${HEALTH_URL}"

# Install kubectl if needed
if ! command -v kubectl &> /dev/null; then
  echo "📦 Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  mv kubectl /usr/local/bin/
fi

# Wait for service to be available
echo "⏳ Waiting for service to be available..."
ELAPSED=0
INTERVAL=5
MAX_WAIT=${TIMEOUT}

while [[ ${ELAPSED} -lt ${MAX_WAIT} ]]; do
  # Try to port-forward and check health
  if kubectl port-forward "svc/${SERVICE}" "8080:${PORT}" -n "${NAMESPACE}" > /dev/null 2>&1 &; then
    PORT_FORWARD_PID=$!
    sleep 2
    
    # Test health endpoint
    if curl -sf "http://localhost:8080/actuator/health" > /dev/null 2>&1; then
      kill ${PORT_FORWARD_PID} 2>/dev/null || true
      wait ${PORT_FORWARD_PID} 2>/dev/null || true
      break
    fi
    
    kill ${PORT_FORWARD_PID} 2>/dev/null || true
    wait ${PORT_FORWARD_PID} 2>/dev/null || true
  fi
  
  echo "   Waiting for service... (${ELAPSED}/${MAX_WAIT} seconds)"
  sleep ${INTERVAL}
  ELAPSED=$((ELAPSED + INTERVAL))
done

# Test health endpoint via port-forward
echo "🔍 Testing health endpoint..."
PORT_FORWARD_PID=""

cleanup() {
  if [[ -n "${PORT_FORWARD_PID}" ]]; then
    kill ${PORT_FORWARD_PID} 2>/dev/null || true
    wait ${PORT_FORWARD_PID} 2>/dev/null || true
  fi
}

trap cleanup EXIT

# Start port-forward
kubectl port-forward "svc/${SERVICE}" "8080:${PORT}" -n "${NAMESPACE}" > /dev/null 2>&1 &
PORT_FORWARD_PID=$!
sleep 3

# Test health endpoint
RETRIES=3
RETRY_COUNT=0
SUCCESS=false

while [[ ${RETRY_COUNT} -lt ${RETRIES} ]]; do
  if curl -sf "http://localhost:8080/actuator/health" > /tmp/health-response.json 2>&1; then
    # Check if health response is valid
    if [[ -f /tmp/health-response.json ]]; then
      STATUS=$(cat /tmp/health-response.json | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "")
      if [[ "${STATUS}" == "UP" ]]; then
        echo "✅ Health check passed (status: ${STATUS})"
        SUCCESS=true
        break
      else
        echo "⚠️  Health check returned status: ${STATUS}"
      fi
    fi
  fi
  
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [[ ${RETRY_COUNT} -lt ${RETRIES} ]]; then
    echo "   Retrying... (${RETRY_COUNT}/${RETRIES})"
    sleep 2
  fi
done

if [[ "${SUCCESS}" == "true" ]]; then
  echo "✅ Smoke tests passed for ${SERVICE}"
  exit 0
else
  echo "❌ Smoke tests failed for ${SERVICE}" >&2
  echo "   Health endpoint did not return UP status" >&2
  
  # Get pod logs for debugging
  echo "📋 Recent pod logs:"
  kubectl logs -n "${NAMESPACE}" -l app="${SERVICE}" --tail=20 2>/dev/null || true
  
  exit 1
fi

