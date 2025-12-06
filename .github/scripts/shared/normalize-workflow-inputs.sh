#!/usr/bin/env bash
# Normalize workflow inputs from both workflow_call and workflow_dispatch
set -euo pipefail

# Accept inputs from both trigger types
WORKFLOW_CALL_SERVICE="${1:-}"
WORKFLOW_CALL_ENVIRONMENT="${2:-}"
WORKFLOW_CALL_IMAGE_TAG="${3:-}"
WORKFLOW_CALL_REASON="${4:-}"
WORKFLOW_DISPATCH_SERVICE="${5:-}"
WORKFLOW_DISPATCH_ENVIRONMENT="${6:-}"
WORKFLOW_DISPATCH_IMAGE_TAG="${7:-}"
WORKFLOW_DISPATCH_REASON="${8:-}"

echo "🔄 Normalizing workflow inputs..."

# Normalize service
if [ -n "$WORKFLOW_CALL_SERVICE" ]; then
  SERVICE="$WORKFLOW_CALL_SERVICE"
else
  SERVICE="$WORKFLOW_DISPATCH_SERVICE"
fi

# Normalize environment
if [ -n "$WORKFLOW_CALL_ENVIRONMENT" ]; then
  ENVIRONMENT="$WORKFLOW_CALL_ENVIRONMENT"
else
  ENVIRONMENT="$WORKFLOW_DISPATCH_ENVIRONMENT"
fi

# Normalize image tag
if [ -n "$WORKFLOW_CALL_IMAGE_TAG" ]; then
  IMAGE_TAG="$WORKFLOW_CALL_IMAGE_TAG"
else
  IMAGE_TAG="$WORKFLOW_DISPATCH_IMAGE_TAG"
fi

# Normalize reason
if [ -n "$WORKFLOW_CALL_REASON" ]; then
  REASON="$WORKFLOW_CALL_REASON"
elif [ -n "$WORKFLOW_DISPATCH_REASON" ]; then
  REASON="$WORKFLOW_DISPATCH_REASON"
else
  REASON="Deployment"
fi

# Output to GITHUB_OUTPUT
echo "service=$SERVICE" >> $GITHUB_OUTPUT
echo "environment=$ENVIRONMENT" >> $GITHUB_OUTPUT
echo "image_tag=$IMAGE_TAG" >> $GITHUB_OUTPUT
echo "reason=$REASON" >> $GITHUB_OUTPUT

echo "✅ Normalized inputs:"
echo "   Service: $SERVICE"
echo "   Environment: $ENVIRONMENT"
echo "   Image Tag: $IMAGE_TAG"
echo "   Reason: $REASON"

