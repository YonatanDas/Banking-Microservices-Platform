#!/usr/bin/env bash
set -euo pipefail
trim() { awk '{$1=$1;print}'; }

GITHUB_SHA="$(printf '%s' "${1-}" | trim)"
SERVICE="$(printf '%s' "${2-}" | trim)"
GITHUB_RUN="$(printf '%s' "${3-}" | trim)"
CACHE_DIR="/tmp/.buildx-cache"
NEW_CACHE_DIR="/tmp/.buildx-cache-new"
REPORT_DIR=".ci_artifacts/${SERVICE}/${GITHUB_SHA}/build/jar-files"

# Validate SERVICE_DIR is set and exists
if [ -z "${SERVICE_DIR:-}" ]; then
  echo "❌ ERROR: SERVICE_DIR is not set. This should be set by 00-resolve-service-path.sh" >&2
  exit 1
fi

if [ ! -d "${SERVICE_DIR}" ]; then
  echo "❌ ERROR: SERVICE_DIR does not exist: ${SERVICE_DIR}" >&2
  exit 1
fi

echo "✅ SERVICE_DIR validated: ${SERVICE_DIR}"

mkdir -p "${REPORT_DIR}"

IMAGE_TAG="${GITHUB_RUN}"
IMAGE_URI="${SERVICE}:${IMAGE_TAG}"

echo "🧱 Building Docker image locally: ${IMAGE_URI}"

docker buildx use mybuilder 
docker buildx inspect --bootstrap
docker buildx build \
  --cache-from "type=local,src=${CACHE_DIR}" \
  --cache-to "type=local,dest=${NEW_CACHE_DIR},mode=max" \
  --target builder \
  -f ${SERVICE_DIR}/Dockerfile \
  ${SERVICE_DIR} || true

docker buildx build \
  --cache-from "type=local,src=${CACHE_DIR}" \
  --cache-to "type=local,dest=${NEW_CACHE_DIR},mode=max" \
  --load \
  -t ${SERVICE}:${IMAGE_TAG} \
  -f ${SERVICE_DIR}/Dockerfile \
  ${SERVICE_DIR}

