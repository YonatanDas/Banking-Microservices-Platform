#!/usr/bin/env bash
set -e

SERVICE_DIR=$1
REPORT_NAME=$(basename "$SERVICE_DIR")-trivy-report.txt

echo "🔎 Running Trivy FS scan on $SERVICE_DIR"

mkdir -p trivy-reports
trivy fs \
  --exit-code 0 \
  --no-progress \
  --severity HIGH,CRITICAL \
  --format table \
  -o "trivy-reports/$REPORT_NAME" \
  "$SERVICE_DIR"

echo "✅ Scan complete: trivy-reports/$REPORT_NAME"