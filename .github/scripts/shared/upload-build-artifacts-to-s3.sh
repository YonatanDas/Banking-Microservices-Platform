#!/usr/bin/env bash
set -euo pipefail

# Required input arguments
S3_BUCKET="${1:-}"
S3_PREFIX="${2:-}"
ARTIFACTS_DIR="${3:-}"
WORKFLOW="${4:-}"

TIMESTAMP=$(date +%d-%m-%Y-%H:%M:%S)
RUN_ID="${RUN_ID:-$TIMESTAMP}"

echo "Preparing upload:"
echo "  Bucket:        ${S3_BUCKET}"
echo "  Prefix:        ${S3_PREFIX}"
echo "  Artifacts Dir: ${ARTIFACTS_DIR}"
echo "  Workflow:      ${WORKFLOW}"
echo "  Run ID:        ${RUN_ID}"

# Compress artifacts
tar czf artifacts.tar.gz "${ARTIFACTS_DIR}"

# Build S3 path
S3_PATH="s3://${S3_BUCKET}/${S3_PREFIX}/${WORKFLOW}/${RUN_ID}/artifacts.tar.gz"

echo "Uploading to ${S3_PATH}..."

aws s3 cp artifacts.tar.gz "${S3_PATH}"

echo "Upload complete!"

