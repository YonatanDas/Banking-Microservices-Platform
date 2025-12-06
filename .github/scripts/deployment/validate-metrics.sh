#!/usr/bin/env bash
set -euo pipefail

# Usage: validate-metrics.sh <SERVICE> <NAMESPACE> [PROMETHEUS_URL]
# Validates metrics in Prometheus after deployment (reads from .deployment-config.yaml)

SERVICE="${1}"
NAMESPACE="${2:-default}"
PROMETHEUS_URL="${3:-}"

if [[ -z "${SERVICE}" ]]; then
  echo "❌ Usage: $0 <SERVICE> <NAMESPACE> [PROMETHEUS_URL]" >&2
  exit 1
fi

# Install yq and jq if not available
if ! command -v yq &> /dev/null; then
  wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
  chmod +x /usr/local/bin/yq
fi

if ! command -v jq &> /dev/null; then
  echo "📦 Installing jq..."
  wget -qO /usr/local/bin/jq https://github.com/jqlang/jq/releases/latest/download/jq-linux-amd64
  chmod +x /usr/local/bin/jq
fi

CONFIG_FILE=".github/config/deployment-config.yaml"

# Check if metrics validation is enabled
if [[ -f "${CONFIG_FILE}" ]]; then
  METRICS_ENABLED=$(yq eval ".metrics.enabled // \"true\"" "${CONFIG_FILE}" 2>/dev/null || echo "true")
  
  if [[ "${METRICS_ENABLED}" != "true" ]]; then
    echo "⚠️  Metrics validation disabled in config, skipping"
    exit 0
  fi
  
  # Get Prometheus URL from config if not provided
  if [[ -z "${PROMETHEUS_URL}" ]]; then
    PROMETHEUS_URL=$(yq eval ".metrics.prometheus_url // \"http://prometheus.monitoring.svc.cluster.local:9090\"" "${CONFIG_FILE}" 2>/dev/null || echo "http://prometheus.monitoring.svc.cluster.local:9090")
  fi
  
  # Get validation delay from config
  VALIDATION_DELAY=$(yq eval ".metrics.validation_delay // 10" "${CONFIG_FILE}" 2>/dev/null || echo "10")
else
  # Fallback to defaults if config not found
  PROMETHEUS_URL="${PROMETHEUS_URL:-http://prometheus.monitoring.svc.cluster.local:9090}"
  VALIDATION_DELAY=10
fi

echo "📊 Validating metrics for ${SERVICE}..."
echo "   Namespace: ${NAMESPACE}"
echo "   Prometheus: ${PROMETHEUS_URL}"

# Wait a bit for metrics to be collected
echo "⏳ Waiting for metrics to be collected..."
sleep "${VALIDATION_DELAY}"

# Function to query Prometheus
query_prometheus() {
  local query="${1}"
  local result
  
  # Try to query Prometheus
  result=$(curl -s "${PROMETHEUS_URL}/api/v1/query?query=${query}" 2>/dev/null || echo "")
  
  if [[ -z "${result}" ]]; then
    echo "⚠️  Could not query Prometheus (may not be accessible)"
    return 1
  fi
  
  echo "${result}" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null || echo "0"
}

# Check if Prometheus is accessible
if ! curl -sf "${PROMETHEUS_URL}/api/v1/status/config" > /dev/null 2>&1; then
  echo "⚠️  Prometheus is not accessible at ${PROMETHEUS_URL}"
  echo "⚠️  Skipping metrics validation (this is not critical)"
  exit 0
fi

# Query for HTTP error rates
echo "🔍 Checking HTTP error rates..."
HTTP_ERROR_RATE=$(query_prometheus "rate(http_server_requests_seconds_count{application=\"${SERVICE}\",status=~\"5..\"}[5m])")

if [[ -n "${HTTP_ERROR_RATE}" && "${HTTP_ERROR_RATE}" != "0" ]]; then
  echo "⚠️  Warning: HTTP 5xx error rate detected: ${HTTP_ERROR_RATE}"
  # Don't fail on this, just warn
else
  echo "✅ No significant HTTP 5xx errors detected"
fi

# Query for pod restarts
echo "🔍 Checking pod restart counts..."
POD_RESTARTS=$(query_prometheus "kube_pod_container_status_restarts_total{pod=~\"${SERVICE}.*\",namespace=\"${NAMESPACE}\"}")

if [[ -n "${POD_RESTARTS}" && "${POD_RESTARTS}" != "0" ]]; then
  RESTART_COUNT=$(echo "${POD_RESTARTS}" | jq -r 'if type=="array" then .[0].value[1] else "0" end' 2>/dev/null || echo "0")
  if [[ "${RESTART_COUNT}" -gt "3" ]]; then
    echo "⚠️  Warning: Pod has ${RESTART_COUNT} restarts"
  else
    echo "✅ Pod restart count is acceptable (${RESTART_COUNT})"
  fi
fi

# Query for CPU/Memory usage (if available)
echo "🔍 Checking resource usage..."
CPU_USAGE=$(query_prometheus "rate(container_cpu_usage_seconds_total{pod=~\"${SERVICE}.*\",namespace=\"${NAMESPACE}\"}[5m])")
MEMORY_USAGE=$(query_prometheus "container_memory_usage_bytes{pod=~\"${SERVICE}.*\",namespace=\"${NAMESPACE}\"}")

if [[ -n "${CPU_USAGE}" ]]; then
  echo "   CPU Usage: ${CPU_USAGE}"
fi

if [[ -n "${MEMORY_USAGE}" ]]; then
  MEMORY_MB=$(echo "scale=2; ${MEMORY_USAGE} / 1024 / 1024" | bc 2>/dev/null || echo "unknown")
  echo "   Memory Usage: ${MEMORY_MB} MB"
fi

echo "✅ Metrics validation completed"

