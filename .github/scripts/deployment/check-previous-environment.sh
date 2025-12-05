#!/usr/bin/env bash
set -euo pipefail

# Usage: check-previous-environment.sh <SERVICE> <IMAGE_TAG> <TARGET_ENV>
# Validates that an image was tested in the previous environment before promotion (reads from .deployment-config.yaml)

SERVICE="${1}"
IMAGE_TAG="${2}"
TARGET_ENV="${3}"

if [[ -z "${SERVICE}" || -z "${IMAGE_TAG}" || -z "${TARGET_ENV}" ]]; then
  echo "❌ Usage: $0 <SERVICE> <IMAGE_TAG> <TARGET_ENV>" >&2
  exit 1
fi

# Install yq if not available
if ! command -v yq &> /dev/null; then
  wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
  chmod +x /usr/local/bin/yq
fi

CONFIG_FILE=".github/workflows/.deployment-config.yaml"

# Check if validation is enabled for this environment
if [[ -f "${CONFIG_FILE}" ]]; then
  ENABLED=$(yq eval ".previous_environment_validation.${TARGET_ENV}.enabled // \"true\"" "${CONFIG_FILE}" 2>/dev/null || echo "true")
  
  if [[ "${ENABLED}" != "true" ]]; then
    echo "⚠️  Previous environment validation disabled for ${TARGET_ENV} in config"
    exit 0
  fi
  
  # Get required environment from config
  PREV_ENV=$(yq eval ".previous_environment_validation.${TARGET_ENV}.required_env" "${CONFIG_FILE}" 2>/dev/null || echo "")
  MESSAGE=$(yq eval ".previous_environment_validation.${TARGET_ENV}.message // \"Image must be deployed to previous environment first\"" "${CONFIG_FILE}" 2>/dev/null || echo "Image must be deployed to previous environment first")
else
  # Fallback to default behavior if config not found
  case "${TARGET_ENV}" in
    stag)
      PREV_ENV="dev"
      MESSAGE="Image must be deployed to dev environment first"
      ;;
    prod)
      PREV_ENV="stag"
      MESSAGE="Image must be deployed to staging environment first"
      ;;
    *)
      echo "⚠️  No previous environment validation required for ${TARGET_ENV}"
      exit 0
      ;;
  esac
fi

# If no previous environment configured, skip validation
if [[ -z "${PREV_ENV}" ]]; then
  echo "⚠️  No previous environment configured for ${TARGET_ENV}"
  exit 0
fi

# Determine Helm values file path
ENV_FILE="helm/environments/${PREV_ENV}-env/image-tags.yaml"

echo "🔍 Checking if image ${IMAGE_TAG} was tested in ${PREV_ENV} environment..."

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "⚠️  Previous environment file not found: ${ENV_FILE}"
  echo "⚠️  Skipping previous environment validation"
  exit 0
fi

# Check image tag in previous environment
PREV_TAG=$(yq eval ".${SERVICE}.image.tag" "${ENV_FILE}" 2>/dev/null || echo "")

if [[ -z "${PREV_TAG}" ]]; then
  echo "⚠️  Could not find ${SERVICE} image tag in ${PREV_ENV} environment"
  echo "⚠️  Skipping previous environment validation"
  exit 0
fi

if [[ "${PREV_TAG}" == "${IMAGE_TAG}" ]]; then
  echo "✅ Image ${IMAGE_TAG} has been tested in ${PREV_ENV} environment"
  exit 0
else
  echo "❌ ${MESSAGE}" >&2
  echo "   Current ${PREV_ENV} tag: ${PREV_TAG}" >&2
  echo "   You are trying to deploy: ${IMAGE_TAG}" >&2
  echo "" >&2
  echo "💡 Best Practice: Deploy to ${PREV_ENV} first, test thoroughly, then promote to ${TARGET_ENV}" >&2
  exit 1
fi

