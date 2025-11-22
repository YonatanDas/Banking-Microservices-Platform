#!/usr/bin/env bash
set -euo pipefail
trim() { awk '{$1=$1;print}'; }

GITHUB_SHA="$(printf '%s' "${1-}" | trim)"
SERVICE="$(printf '%s' "${2-}" | trim)"
GITHUB_RUN="$(printf '%s' "${3-}" | trim)"
CACHE_DIR="/tmp/.buildx-cache"
NEW_CACHE_DIR="/tmp/.buildx-cache-new"
REPORT_DIR=".ci_artifacts/${SERVICE}/${GITHUB_SHA}/build/jar-files"


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
  --load \
  -t ${SERVICE}:builder \
  -f ${SERVICE_DIR}/Dockerfile \
  ${SERVICE_DIR}

