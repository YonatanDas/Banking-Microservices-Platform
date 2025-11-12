#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR=".buildx-cache"
NEW_CACHE_DIR=".buildx-cache-new"
REPORT_DIR=".ci_artifacts"
mkdir -p "${CACHE_DIR}" "${REPORT_DIR}"

IMAGE_TAG="pre-scan"
IMAGE_URI="${SERVICE}:${IMAGE_TAG}"

echo "🧱 Building Docker image locally: ${IMAGE_URI}"

docker buildx use default || docker buildx create --use --name "${SERVICE}-builder"
docker buildx inspect --bootstrap

docker buildx build \
  --target builder \
  --load \
  -t ${SERVICE}:builder \
  -f ${SERVICE_DIR}/Dockerfile \
  ${SERVICE_DIR}

echo "📦 Extracting JAR file from image for scanning..."
CID=$(docker create ${SERVICE}:builder)
docker cp "${CID}:/app/target" "${REPORT_DIR}/jar-files"
docker rm "${CID}"

echo "✅ Build complete. Image ready for Trivy scan: ${IMAGE_URI}"