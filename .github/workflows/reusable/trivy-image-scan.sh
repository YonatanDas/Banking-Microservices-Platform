#!/bin/bash
set -e

SERVICE=$1
REGISTRY=$2
AWS_REGION=$3

echo "🧪 Running Trivy image scan for ${SERVICE}..."


trivy image \
  --exit-code 0 \
  --skip-db-update \
  --ignore-unfixed \
  --format table \
  --output "${SERVICE}-trivy-image-report.txt" \
  --severity HIGH,CRITICAL \
  "${REGISTRY}/${SERVICE}:latest"

echo "✅ Trivy scan completed. Report saved: ${SERVICE}-trivy-image-report.txt"