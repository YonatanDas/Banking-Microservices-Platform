#!/usr/bin/env bash
set -euo pipefail

# Usage: validate-deployment-window.sh <ENVIRONMENT>
# Validates that deployment is within allowed deployment window (reads from .deployment-config.yaml)

ENVIRONMENT="${1}"

if [[ -z "${ENVIRONMENT}" ]]; then
  echo "❌ Usage: $0 <ENVIRONMENT>" >&2
  exit 1
fi

# Install yq if not available
if ! command -v yq &> /dev/null; then
  wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
  chmod +x /usr/local/bin/yq
fi

CONFIG_FILE=".github/workflows/.deployment-config.yaml"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "⚠️  Config file not found: ${CONFIG_FILE}, using default behavior"
  echo "✅ Deployment window check skipped (config not found)"
  exit 0
fi

echo "🕐 Validating deployment window for ${ENVIRONMENT} environment..."

# Check if deployment window validation is enabled for this environment
ENABLED=$(yq eval ".deployment_windows.${ENVIRONMENT}.enabled" "${CONFIG_FILE}" 2>/dev/null || echo "false")

if [[ "${ENABLED}" != "true" ]]; then
  echo "✅ Deployment window validation disabled for ${ENVIRONMENT}, allowing deployment"
  exit 0
fi

# Get deployment window restrictions from config
RESTRICTIONS=$(yq eval ".deployment_windows.${ENVIRONMENT}.restrictions" "${CONFIG_FILE}" 2>/dev/null || echo "[]")

if [[ "${RESTRICTIONS}" == "[]" || "${RESTRICTIONS}" == "null" ]]; then
  echo "✅ No restrictions configured for ${ENVIRONMENT}, allowing deployment"
  exit 0
fi

# Get timezone from first restriction (default to America/New_York)
TIMEZONE=$(yq eval ".deployment_windows.${ENVIRONMENT}.restrictions[0].timezone // \"America/New_York\"" "${CONFIG_FILE}" 2>/dev/null || echo "America/New_York")

# Get current time in specified timezone
CURRENT_HOUR=$(TZ="${TIMEZONE}" date +%H)
CURRENT_DAY=$(TZ="${TIMEZONE}" date +%u)  # 1=Monday, 7=Sunday
CURRENT_TIME=$(TZ="${TIMEZONE}" date +"%Y-%m-%d %H:%M:%S %Z")

echo "   Current time (${TIMEZONE}): ${CURRENT_TIME}"
echo "   Current hour: ${CURRENT_HOUR}"
echo "   Day of week: ${CURRENT_DAY}"

# Check restrictions from config
RESTRICTION_COUNT=$(yq eval ".deployment_windows.${ENVIRONMENT}.restrictions | length" "${CONFIG_FILE}" 2>/dev/null || echo "0")

for ((i=0; i<RESTRICTION_COUNT; i++)); do
  DAYS=$(yq eval ".deployment_windows.${ENVIRONMENT}.restrictions[${i}].days[]" "${CONFIG_FILE}" 2>/dev/null || echo "")
  HOURS=$(yq eval ".deployment_windows.${ENVIRONMENT}.restrictions[${i}].hours[]" "${CONFIG_FILE}" 2>/dev/null || echo "")
  MESSAGE=$(yq eval ".deployment_windows.${ENVIRONMENT}.restrictions[${i}].message // \"Deployment blocked by deployment window restriction\"" "${CONFIG_FILE}" 2>/dev/null || echo "Deployment blocked")
  
  # Check if current day is in restricted days
  DAY_MATCHED=false
  for day in $DAYS; do
    if [[ "${day}" == "${CURRENT_DAY}" ]]; then
      DAY_MATCHED=true
      break
    fi
  done
  
  # Check if current hour is in restricted hours
  HOUR_MATCHED=false
  for hour in $HOURS; do
    if [[ "${hour}" == "${CURRENT_HOUR}" ]]; then
      HOUR_MATCHED=true
      break
    fi
  done
  
  # If both day and hour match, deployment is blocked
  if [[ "${DAY_MATCHED}" == "true" && "${HOUR_MATCHED}" == "true" ]]; then
    echo "❌ ${MESSAGE}" >&2
    echo "   Current time: ${CURRENT_TIME}" >&2
    exit 1
  fi
done

echo "✅ Deployment window validated - deployment allowed"
exit 0

