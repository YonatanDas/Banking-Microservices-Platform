#!/usr/bin/env bash
set -euo pipefail

# --- sanitize inputs (trim spaces/newlines) ---
trim() { awk '{$1=$1;print}'; }

SERVICE="$(printf '%s' "${1-}" | trim)"
REGISTRY="$(printf '%s' "${2-}" | trim)"
AWS_REGION="$(printf '%s' "${3-us-east-1}" | trim)"
GITHUB_RUN="$(printf '%s' "${4-}" | trim)"

if [[ -z "${SERVICE}" || -z "${REGISTRY}" ]]; then
  echo "❌ Usage: $0 <SERVICE> <REGISTRY> [AWS_REGION]" >&2
  exit 1
fi

IMAGE_TAG="${GITHUB_RUN}"
LOCAL_IMAGE="${SERVICE}:builder"
REMOTE_IMAGE="${REGISTRY}/${SERVICE}:${IMAGE_TAG}"

echo "🔎 Debug (local images matching '${SERVICE}')"
docker images --format '{{.Repository}}:{{.Tag}}' | grep -E "^${SERVICE}:" || true

# Ensure the local image exists (built with --load in 04a-build-image.sh)
if ! docker image inspect "${LOCAL_IMAGE}" >/dev/null 2>&1; then
  echo "❌ Local image '${LOCAL_IMAGE}' not found. Did you build with --load?" >&2
  exit 1
fi

echo "🚀 Tagging and pushing ${LOCAL_IMAGE} → ${REMOTE_IMAGE}"
docker tag "${LOCAL_IMAGE}" "${REMOTE_IMAGE}"
docker push "${REMOTE_IMAGE}"

echo "✅ Push complete: ${REMOTE_IMAGE}"