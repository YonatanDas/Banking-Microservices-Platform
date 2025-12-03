#!/usr/bin/env bash
set -euo pipefail

# Usage: check-previous-environment.sh <SERVICE> <IMAGE_TAG> <TARGET_ENV>
# Validates that an image was tested in the previous environment before promotion

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

# Determine previous environment
case "${TARGET_ENV}" in
  stag)
    PREV_ENV="dev"
    ENV_FILE="helm/environments/dev-env/image-tags.yaml"
    ;;
  prod)
    PREV_ENV="stag"
    ENV_FILE="helm/environments/stag-env/image-tags.yaml"
    ;;
  *)
    echo "⚠️  No previous environment validation required for ${TARGET_ENV}"
    exit 0
    ;;
esac

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
  echo "❌ Image ${IMAGE_TAG} has NOT been tested in ${PREV_ENV} environment" >&2
  echo "   Current ${PREV_ENV} tag: ${PREV_TAG}" >&2
  echo "   You are trying to deploy: ${IMAGE_TAG}" >&2
  echo "" >&2
  echo "💡 Best Practice: Deploy to ${PREV_ENV} first, test thoroughly, then promote to ${TARGET_ENV}" >&2
  exit 1
fi

