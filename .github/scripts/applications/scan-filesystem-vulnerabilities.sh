#!/bin/bash
set -e

SERVICE_DIR="$1"
ROOT_DIR="$(git rev-parse --show-toplevel)"
TARGET_PATH="$ROOT_DIR/$SERVICE_DIR"

echo "🔎 Running Trivy FS scan on $TARGET_PATH"

if [ ! -d "$TARGET_PATH" ]; then
  echo "❌ Directory not found: $TARGET_PATH"
  exit 1
fi

# Clean broken symlinks or unreadable files before scanning
echo "🧹 Cleaning up broken symlinks and unreadable files..."
find "$TARGET_PATH" -xtype l -delete || true
find "$TARGET_PATH" ! -readable -exec rm -f {} \; 2>/dev/null || true

# Skip Maven target directory
if [ -d "$TARGET_PATH/target" ]; then
  echo "🧹 Skipping Maven target directory from scan..."
  rm -rf "$TARGET_PATH/target"
fi

# Extract service name from SERVICE_DIR (e.g., "applications/accounts" -> "accounts")
SERVICE_NAME=$(basename "${SERVICE_DIR}")

# Run Trivy FS scan
trivy fs "$TARGET_PATH" \
  --exit-code 0 \
  --ignore-unfixed \
  --scanners vuln,secret,config \
  --severity HIGH,CRITICAL \
  --format table \
  --output "$ROOT_DIR/${SERVICE_NAME}-trivy-FS-report.txt"

echo "✅ Trivy FS scan completed successfully for $SERVICE_DIR"

# Check for critical vulnerabilities
REPORT_FILE="$ROOT_DIR/${SERVICE_NAME}-trivy-FS-report.txt"
echo "🔎 Checking for critical vulnerabilities..."
if [ -f "$REPORT_FILE" ]; then
  if grep -qi "CRITICAL" "$REPORT_FILE"; then
    echo "❌ Critical vulnerabilities found in filesystem scan!"
    exit 1
  fi
  echo "✅ No critical vulnerabilities found in filesystem scan"
else
  echo "⚠️ Scan report not found: $REPORT_FILE"
  exit 1
fi