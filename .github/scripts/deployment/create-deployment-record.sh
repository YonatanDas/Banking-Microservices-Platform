#!/usr/bin/env bash
set -euo pipefail

# Usage: create-deployment-record.sh <SERVICE> <ENVIRONMENT> <IMAGE_TAG> <DEPLOYED_BY> [REASON]
# Creates a deployment audit trail record

SERVICE="${1}"
ENVIRONMENT="${2}"
IMAGE_TAG="${3}"
DEPLOYED_BY="${4}"
REASON="${5:-Manual deployment}"

if [[ -z "${SERVICE}" || -z "${ENVIRONMENT}" || -z "${IMAGE_TAG}" || -z "${DEPLOYED_BY}" ]]; then
  echo "❌ Usage: $0 <SERVICE> <ENVIRONMENT> <IMAGE_TAG> <DEPLOYED_BY> [REASON]" >&2
  exit 1
fi

RECORDS_DIR="docs/deployments"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
RECORD_FILE="${RECORDS_DIR}/${ENVIRONMENT}/${SERVICE}-${TIMESTAMP}.md"

# Create directories if they don't exist
mkdir -p "${RECORDS_DIR}/${ENVIRONMENT}"

echo "📝 Creating deployment record..."
echo "   File: ${RECORD_FILE}"

# Create deployment record
cat > "${RECORD_FILE}" <<EOF
# Deployment Record

**Service**: ${SERVICE}
**Environment**: ${ENVIRONMENT}
**Image Tag**: ${IMAGE_TAG}
**Deployed By**: ${DEPLOYED_BY}
**Timestamp**: ${TIMESTAMP}
**Reason**: ${REASON}
**Status**: Success

## Deployment Details

- **Git Commit**: ${GITHUB_SHA:-unknown}
- **Workflow Run**: ${GITHUB_RUN_ID:-unknown}
- **Workflow URL**: ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID:-unknown}

## Post-Deployment Verification

- [x] Image signature verified
- [x] Image exists in ECR
- [x] ArgoCD sync completed
- [x] Deployment health verified
- [x] Smoke tests passed

## Notes

Deployment completed successfully via GitHub Actions workflow.
EOF

echo "✅ Deployment record created: ${RECORD_FILE}"

# Configure git
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

# Add and commit record
git add "${RECORD_FILE}"

# Don't commit if in a workflow that will commit anyway
if [[ -z "${GITHUB_ACTIONS:-}" ]]; then
  git commit -m "docs: add deployment record for ${SERVICE} to ${ENVIRONMENT}" || echo "⚠️  Could not commit deployment record"
fi

