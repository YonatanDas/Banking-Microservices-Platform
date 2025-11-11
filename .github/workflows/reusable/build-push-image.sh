#!/bin/bash
set -e

SERVICE=$1
SERVICE_DIR=$2
REGISTRY=$3
AWS_REGION=$4

IMAGE_TAG=$(echo "${GITHUB_SHA}" | cut -c1-7)
echo "🚀 Building Docker image for $SERVICE..."
echo "Tag: ${IMAGE_TAG}"

# Build and push
docker buildx build "$SERVICE_DIR" \
  --push \
  --cache-from type=tmp,src=/tmp/.buildx-cache \
  --cache-to type=tmp,dest=/tmp/.buildx-cache-new,mode=max \
  -t "${REGISTRY}/${SERVICE}:${IMAGE_TAG}" \
  -t "${REGISTRY}/${SERVICE}:latest"

echo "✅ Image pushed: ${REGISTRY}/${SERVICE}:${IMAGE_TAG}"