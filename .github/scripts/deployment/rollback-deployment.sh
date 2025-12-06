#!/usr/bin/env bash
set -euo pipefail

# Usage: rollback-deployment.sh <SERVICE> <ENVIRONMENT> [PREVIOUS_TAG]
# Rolls back deployment to previous image tag

SERVICE="${1}"
ENVIRONMENT="${2}"
PREVIOUS_TAG="${3:-}"

if [[ -z "${SERVICE}" || -z "${ENVIRONMENT}" ]]; then
  echo "❌ Usage: $0 <SERVICE> <ENVIRONMENT> [PREVIOUS_TAG]" >&2
  exit 1
fi

# Install yq if not available
if ! command -v yq &> /dev/null; then
  wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
  chmod +x /usr/local/bin/yq
fi

TAGS_FILE="helm/environments/${ENVIRONMENT}-env/image-tags.yaml"

echo "⏮️  Rolling back deployment..."
echo "   Service: ${SERVICE}"
echo "   Environment: ${ENVIRONMENT}"
echo "   Tags file: ${TAGS_FILE}"

# Configure git
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git config pull.rebase true

# Detect current branch
if [ -n "${GITHUB_HEAD_REF:-}" ]; then
  CURRENT_BRANCH="${GITHUB_HEAD_REF}"
elif [ -n "${GITHUB_REF:-}" ]; then
  CURRENT_BRANCH="${GITHUB_REF#refs/heads/}"
else
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
fi

CURRENT_BRANCH="${CURRENT_BRANCH:-main}"

# Map service names
case "${SERVICE}" in
  gatewayserver)
    HELM_SERVICE="gateway"
    ;;
  *)
    HELM_SERVICE="${SERVICE}"
    ;;
esac

# Get previous tag from Git history if not provided
if [[ -z "${PREVIOUS_TAG}" ]]; then
  echo "🔍 Finding previous image tag from Git history..."
  
  # Get the previous commit that modified this file
  PREVIOUS_COMMIT=$(git log -1 --skip=1 --format="%H" -- "${TAGS_FILE}" 2>/dev/null || echo "")
  
  if [[ -z "${PREVIOUS_COMMIT}" ]]; then
    echo "❌ Could not find previous commit modifying ${TAGS_FILE}" >&2
    echo "💡 Please provide PREVIOUS_TAG manually" >&2
    exit 1
  fi
  
  PREVIOUS_TAG=$(git show "${PREVIOUS_COMMIT}:${TAGS_FILE}" 2>/dev/null | yq eval ".${HELM_SERVICE}.image.tag" 2>/dev/null || echo "")
  
  if [[ -z "${PREVIOUS_TAG}" ]]; then
    echo "❌ Could not extract previous tag from commit ${PREVIOUS_COMMIT}" >&2
    exit 1
  fi
  
  echo "   Found previous tag: ${PREVIOUS_TAG} (from commit ${PREVIOUS_COMMIT:0:7})"
fi

# Get current tag
CURRENT_TAG=$(yq eval ".${HELM_SERVICE}.image.tag" "${TAGS_FILE}" 2>/dev/null || echo "")

if [[ "${CURRENT_TAG}" == "${PREVIOUS_TAG}" ]]; then
  echo "ℹ️  Current tag is already ${PREVIOUS_TAG}, no rollback needed"
  exit 0
fi

echo "📋 Rollback details:"
echo "   Current tag: ${CURRENT_TAG}"
echo "   Previous tag: ${PREVIOUS_TAG}"

# Sync with remote
echo "🔄 Syncing with remote..."
git fetch origin "${CURRENT_BRANCH}"
git reset --hard "origin/${CURRENT_BRANCH}"

# Update image tag
echo "🔄 Updating image tag to ${PREVIOUS_TAG}..."
yq eval ".${HELM_SERVICE}.image.tag = \"${PREVIOUS_TAG}\"" -i "${TAGS_FILE}"

# Verify the update
if yq eval ".${HELM_SERVICE}.image.tag" "${TAGS_FILE}" | grep -q "^${PREVIOUS_TAG}$"; then
  echo "✅ Successfully updated tag to ${PREVIOUS_TAG}"
else
  echo "❌ Failed to verify tag update" >&2
  exit 1
fi

# Commit and push
git add "${TAGS_FILE}"
git commit -m "rollback: revert ${HELM_SERVICE} to ${PREVIOUS_TAG} in ${ENVIRONMENT} [skip ci]"

MAX_RETRIES=5
RETRY_COUNT=0

while [[ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]]; do
  if git push origin "${CURRENT_BRANCH}"; then
    echo "✅ Rollback committed and pushed successfully"
    echo "🔄 ArgoCD will automatically sync the rollback"
    exit 0
  fi
  
  RETRY_COUNT=$((RETRY_COUNT + 1))
  
  if [[ ${RETRY_COUNT} -ge ${MAX_RETRIES} ]]; then
    echo "❌ Failed to push rollback after ${MAX_RETRIES} retries" >&2
    exit 1
  fi
  
  echo "⚠️  Push failed, retrying... (${RETRY_COUNT}/${MAX_RETRIES})"
  git fetch origin "${CURRENT_BRANCH}"
  git rebase "origin/${CURRENT_BRANCH}" || git reset --hard "origin/${CURRENT_BRANCH}"
  
  # Re-apply change if needed
  yq eval ".${HELM_SERVICE}.image.tag = \"${PREVIOUS_TAG}\"" -i "${TAGS_FILE}"
  git add "${TAGS_FILE}"
  
  if ! git diff --cached --quiet; then
    git commit -m "rollback: revert ${HELM_SERVICE} to ${PREVIOUS_TAG} in ${ENVIRONMENT} [skip ci]"
  fi
  
  sleep 2
done

