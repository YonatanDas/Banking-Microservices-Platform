#!/usr/bin/env bash
set -euo pipefail

# Usage: validate-deployment-window.sh <ENVIRONMENT> [TIMEZONE]
# Validates that deployment is within allowed deployment window

ENVIRONMENT="${1}"
TIMEZONE="${2:-America/New_York}"

if [[ -z "${ENVIRONMENT}" ]]; then
  echo "❌ Usage: $0 <ENVIRONMENT> [TIMEZONE]" >&2
  exit 1
fi

echo "🕐 Validating deployment window for ${ENVIRONMENT} environment..."

# Staging has no restrictions
if [[ "${ENVIRONMENT}" == "stag" || "${ENVIRONMENT}" == "dev" ]]; then
  echo "✅ Staging/dev deployments allowed at any time"
  exit 0
fi

# Production has deployment windows
if [[ "${ENVIRONMENT}" == "prod" ]]; then
  # Get current time in specified timezone
  CURRENT_HOUR=$(TZ="${TIMEZONE}" date +%H)
  CURRENT_DAY=$(TZ="${TIMEZONE}" date +%u)  # 1=Monday, 7=Sunday
  CURRENT_TIME=$(TZ="${TIMEZONE}" date +"%Y-%m-%d %H:%M:%S %Z")
  
  echo "   Current time (${TIMEZONE}): ${CURRENT_TIME}"
  echo "   Current hour: ${CURRENT_HOUR}"
  echo "   Day of week: ${CURRENT_DAY}"
  
  # Block deployments during business hours (9 AM - 5 PM EST, Monday-Friday)
  if [[ "${CURRENT_DAY}" -ge 1 && "${CURRENT_DAY}" -le 5 ]]; then
    # Monday-Friday
    if [[ "${CURRENT_HOUR}" -ge 9 && "${CURRENT_HOUR}" -lt 17 ]]; then
      echo "❌ Production deployments are blocked during business hours (9 AM - 5 PM ${TIMEZONE})" >&2
      echo "   Current time: ${CURRENT_TIME}" >&2
      echo "   Allowed windows: After 5 PM or before 9 AM, Monday-Friday, or anytime on weekends" >&2
      exit 1
    fi
  fi
  
  echo "✅ Deployment window validated - production deployment allowed"
  exit 0
fi

# Unknown environment
echo "⚠️  Unknown environment: ${ENVIRONMENT}, allowing deployment"
exit 0

