#!/usr/bin/env bash
set -euo pipefail

# Usage: verify-deployment-health.sh <SERVICE> <NAMESPACE> [TIMEOUT_SECONDS]
# Verifies that Kubernetes deployment is ready and pods are healthy

SERVICE="${1}"
NAMESPACE="${2:-default}"
TIMEOUT="${3:-300}"

if [[ -z "${SERVICE}" ]]; then
  echo "❌ Usage: $0 <SERVICE> <NAMESPACE> [TIMEOUT_SECONDS]" >&2
  exit 1
fi

# Determine deployment name (usually {service}-deployment)
DEPLOYMENT_NAME="${SERVICE}-deployment"

echo "🏥 Verifying deployment health..."
echo "   Deployment: ${DEPLOYMENT_NAME}"
echo "   Namespace: ${NAMESPACE}"
echo "   Timeout: ${TIMEOUT} seconds"

# Wait for deployment to be available
echo "⏳ Waiting for deployment to be available..."
if kubectl wait --for=condition=available \
  --timeout="${TIMEOUT}s" \
  "deployment/${DEPLOYMENT_NAME}" \
  -n "${NAMESPACE}" 2>/dev/null; then
  echo "✅ Deployment is available"
else
  echo "❌ Deployment did not become available within ${TIMEOUT} seconds" >&2
  exit 1
fi

# Verify pod readiness
echo "🔍 Checking pod readiness..."
READY_REPLICAS=$(kubectl get deployment "${DEPLOYMENT_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
DESIRED_REPLICAS=$(kubectl get deployment "${DEPLOYMENT_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

if [[ -z "${READY_REPLICAS}" ]]; then
  READY_REPLICAS=0
fi

if [[ "${READY_REPLICAS}" == "${DESIRED_REPLICAS}" && "${READY_REPLICAS}" -gt 0 ]]; then
  echo "✅ All pods are ready (${READY_REPLICAS}/${DESIRED_REPLICAS})"
else
  echo "❌ Pod readiness check failed (${READY_REPLICAS}/${DESIRED_REPLICAS} ready)" >&2
  
  # Get pod status for debugging
  echo "📋 Pod status:"
  kubectl get pods -n "${NAMESPACE}" -l app="${SERVICE}" -o wide 2>/dev/null || true
  
  # Get recent events
  echo "📋 Recent events:"
  kubectl get events -n "${NAMESPACE}" --field-selector involvedObject.name="${DEPLOYMENT_NAME}" --sort-by='.lastTimestamp' | tail -5 || true
  
  exit 1
fi

# Check for crash loop backoff
echo "🔍 Checking for pod failures..."
CRASHING_PODS=$(kubectl get pods -n "${NAMESPACE}" -l app="${SERVICE}" -o jsonpath='{.items[?(@.status.containerStatuses[0].restartCount>3)].metadata.name}' 2>/dev/null || echo "")

if [[ -n "${CRASHING_PODS}" ]]; then
  echo "⚠️  Warning: Some pods have high restart counts"
  for pod in ${CRASHING_PODS}; do
    RESTART_COUNT=$(kubectl get pod "${pod}" -n "${NAMESPACE}" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
    echo "   Pod ${pod}: ${RESTART_COUNT} restarts"
  done
fi

echo "✅ Deployment health verification completed successfully"

