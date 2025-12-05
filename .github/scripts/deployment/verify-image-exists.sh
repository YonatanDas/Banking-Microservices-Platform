#!/usr/bin/env bash
set -euo pipefail

# Usage: verify-image-exists.sh <REGISTRY> <SERVICE> <IMAGE_TAG> <AWS_REGION>
# Verifies that an image exists in ECR

REGISTRY="${1}"
SERVICE="${2}"
IMAGE_TAG="${3}"
AWS_REGION="${4:-us-east-1}"

if [[ -z "${REGISTRY}" || -z "${SERVICE}" || -z "${IMAGE_TAG}" ]]; then
  echo "❌ Usage: $0 <REGISTRY> <SERVICE> <IMAGE_TAG> [AWS_REGION]" >&2
  exit 1
fi

# Extract ECR repository name from registry
# Registry format: <account-id>.dkr.ecr.<region>.amazonaws.com
ECR_REPO="${SERVICE}"

echo "🔍 Verifying image exists in ECR..."
echo "   Repository: ${ECR_REPO}"
echo "   Tag: ${IMAGE_TAG}"
echo "   Region: ${AWS_REGION}"

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
  echo "❌ AWS CLI is not installed" >&2
  exit 1
fi

# Verify image exists
if aws ecr describe-images \
  --repository-name "${ECR_REPO}" \
  --image-ids "imageTag=${IMAGE_TAG}" \
  --region "${AWS_REGION}" > /dev/null 2>&1; then
  echo "✅ Image ${ECR_REPO}:${IMAGE_TAG} exists in ECR"
  
  # Get image details
  IMAGE_DETAILS=$(aws ecr describe-images \
    --repository-name "${ECR_REPO}" \
    --image-ids "imageTag=${IMAGE_TAG}" \
    --region "${AWS_REGION}" \
    --query 'imageDetails[0]' --output json 2>/dev/null || echo "{}")
  
  PUSHED_AT=$(echo "${IMAGE_DETAILS}" | jq -r '.imagePushedAt // "unknown"' 2>/dev/null || echo "unknown")
  echo "📅 Image pushed at: ${PUSHED_AT}"
  
  exit 0
else
  echo "❌ Image ${ECR_REPO}:${IMAGE_TAG} does not exist in ECR" >&2
  echo "💡 Make sure the image was built and pushed successfully" >&2
  exit 1
fi

