#!/usr/bin/env bash
set -euo pipefail

SERVICE=$1
SERVICE_DIR=$2
AWS_REGION=$3
ECR_REGISTRY=$4
IMAGE_TAG=$5

echo "🚧 Building Docker image for $SERVICE..."

cd "$SERVICE_DIR"

docker build -t "$ECR_REGISTRY/$SERVICE:$IMAGE_TAG" .

echo "📦 Pushing image to ECR..."
docker push "$ECR_REGISTRY/$SERVICE:$IMAGE_TAG"

echo "✅ Docker image pushed: $ECR_REGISTRY/$SERVICE:$IMAGE_TAG"