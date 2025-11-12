#!/usr/bin/env bash
set -euo pipefail

# Usage:
# artifact_collect_and_s3.sh "<SERVICE>" "<S3_BUCKET>" [<DEST_PREFIX>]
#
# Example:
# artifact_collect_and_s3.sh "gateway" "my-ci-artifacts55" "builds"

SERVICE="${1:-gateway}"
S3_BUCKET="${2:-}"
DEST_PREFIX="${3:-ci}"
if [ -z "${S3_BUCKET}" ]; then
  echo "ERR: S3 bucket is required" >&2
  exit 2
fi

SHA="${GITHUB_SHA:-unknown}"
TIMESTAMP="$(date -u +"%Y%m%dT%H%M%SZ")"

# actions/download-artifact should have placed everything under ./collected-artifacts/
SRC_DIR="collected-artifacts"
if [ ! -d "${SRC_DIR}" ]; then
  echo "ERR: ${SRC_DIR} not found. Run actions/download-artifact before this script." >&2
  exit 3
fi

# Normalize structure to: collected-artifacts/<artifact-names>/** -> s3://bucket/<DEST_PREFIX>/<service>/<sha>/<timestamp>/
S3_URI="s3://${S3_BUCKET}/${DEST_PREFIX}/${SERVICE}/${SHA}/${TIMESTAMP}/"

echo "Syncing artifacts to ${S3_URI}"
# Optional: generate a manifest
MANIFEST="${SRC_DIR}/S3_MANIFEST.json"
cat > "${MANIFEST}" <<EOF
{
  "service": "${SERVICE}",
  "commit_sha": "${SHA}",
  "timestamp_utc": "${TIMESTAMP}",
  "source_dir": "${SRC_DIR}",
  "destination": "${S3_URI}"
}
EOF

# Sync all artifacts (requires aws creds via OIDC + policy)
aws s3 sync "${SRC_DIR}/" "${S3_URI}" --only-show-errors

echo "Upload complete."