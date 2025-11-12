#!/usr/bin/env bash
set -e

SERVICE_DIR=$1
ROOT_DIR="$(git rev-parse --show-toplevel)"
REPORT_NAME=$(basename "$SERVICE_DIR")-trivy-report.txt

echo "🔎 Running Trivy FS scan on $SERVICE_DIR"

mkdir -p trivy-reports
trivy fs \
  --exit-code 0 \                               # In a real production env will be exit code 1 if severity is HIGH,CRITICAL
  --no-progress \
  --severity HIGH,CRITICAL \          
  --format json \
  --output "${SERVICE}-trivy-FS-report.txt" \
  "$ROOT_DIR/$SERVICE_DIR"

echo "✅ Scan complete: trivy-reports/$REPORT_NAME"