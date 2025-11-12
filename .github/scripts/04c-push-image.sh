#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./04c-push-image.sh <SERVICE> <REGISTRY> <AWS_REGION>
#
# Example:
#   ./04c-push-image.sh gateway 123456789012.dkr.ecr.us-east-1.amazonaws.com us-east-1

SERVICE="${1:-}"
REGISTRY="${2:-}"

if [[ -z "$SERVICE" || -z "$REGISTRY" ]]; then
  echo "❌ Usage: $0 <SERVICE> <REGISTRY> <AWS_REGION>" >&2
  exit 1
fi

IMAGE_TAG="latest"
LOCAL_IMAGE="${SERVICE}:pre-scan"
REMOTE_IMAGE="${REGISTRY}/${SERVICE}:${IMAGE_TAG}"

echo "🚀 Pushing verified image to ECR: ${REMOTE_IMAGE}"
docker tag "${LOCAL_IMAGE}" "${REMOTE_IMAGE}"
docker push "${REMOTE_IMAGE}"

echo "✅ Push complete: ${REMOTE_IMAGE}"