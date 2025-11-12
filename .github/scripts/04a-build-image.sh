#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:-}"
SERVICE_DIR="${2:-}"
REGISTRY="${3:-}"
AWS_REGION="${4:-us-east-1}"

if [[ -z "$SERVICE" || -z "$SERVICE_DIR" || -z "$REGISTRY" ]]; then
  echo "❌ Usage: $0 <SERVICE> <SERVICE_DIR> <REGISTRY> <AWS_REGION>" >&2
  exit 1
fi

CACHE_DIR="/tmp/.buildx-cache"
NEW_CACHE_DIR="/tmp/.buildx-cache-new"
REPORT_DIR=".ci_artifacts/${SERVICE}/${GITHUB_SHA}/build"
mkdir -p "${CACHE_DIR}" "${REPORT_DIR}"

IMAGE_TAG="pre-scan"
IMAGE_URI="${SERVICE}:${IMAGE_TAG}"

echo "🏗️ Building Docker image locally: ${IMAGE_URI}"
docker buildx create --use --name "${SERVICE}-builder" || docker buildx use "${SERVICE}-builder"
docker buildx inspect --bootstrap

docker buildx build \
  --platform linux/amd64 \
  --file "${SERVICE_DIR}/Dockerfile" \
  --cache-from "type=local,src=${CACHE_DIR}" \
  --cache-to "type=local,dest=${NEW_CACHE_DIR},mode=max" \
  --tag "${IMAGE_URI}" \
  --load \ 
  "${SERVICE_DIR}"

mv "${NEW_CACHE_DIR}" "${CACHE_DIR}" || true

# Extract JAR from image for scanning
echo "📦 Extracting JAR file from image..."
CID=$(docker create "${IMAGE_URI}")
docker cp "${CID}:/app/target" "${REPORT_DIR}/jar-files"
docker rm "${CID}"

echo "✅ Build complete. Image ready for scanning."