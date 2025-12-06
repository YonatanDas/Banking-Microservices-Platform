#!/usr/bin/env bash
# Resolve image tag from input or previous environment
set -euo pipefail

SERVICE="$1"
ENVIRONMENT="$2"
PROVIDED_IMAGE_TAG="${3:-}"

if [ -z "$SERVICE" ] || [ -z "$ENVIRONMENT" ]; then
  echo "Usage: $0 <SERVICE> <ENVIRONMENT> [IMAGE_TAG]" >&2
  exit 1
fi

echo "🔍 Resolving image tag for $SERVICE in $ENVIRONMENT..."

if [ -n "$PROVIDED_IMAGE_TAG" ]; then
  IMAGE_TAG="$PROVIDED_IMAGE_TAG"
  echo "✅ Using provided image tag: $IMAGE_TAG"
else
  # Determine previous environment
  case "$ENVIRONMENT" in
    stag)
      PREV_ENV="dev"
      ;;
    prod)
      PREV_ENV="stag"
      ;;
    dev)
      PREV_ENV="dev"
      echo "ℹ️  No previous environment for dev, will use provided tag"
      IMAGE_TAG=""
      ;;
    *)
      PREV_ENV="dev"
      ;;
  esac
  
  # Get image tag from previous environment
  TAGS_FILE="helm/environments/${PREV_ENV}-env/image-tags.yaml"
  
  if [ ! -f "$TAGS_FILE" ]; then
    echo "❌ Image tags file not found: $TAGS_FILE" >&2
    exit 1
  fi
  
  IMAGE_TAG=$(yq eval ".${SERVICE}.image.tag" "$TAGS_FILE" 2>/dev/null || echo "")
  
  if [ -z "$IMAGE_TAG" ]; then
    echo "❌ Could not determine image tag from ${PREV_ENV} environment. Please provide one manually." >&2
    exit 1
  fi
  
  echo "✅ Using image tag from ${PREV_ENV} environment: $IMAGE_TAG"
fi

# Output for GitHub Actions
echo "image_tag=$IMAGE_TAG" >> $GITHUB_OUTPUT
echo "resolved_tag=$IMAGE_TAG" >> $GITHUB_OUTPUT

