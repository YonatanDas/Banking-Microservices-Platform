#!/usr/bin/env bash
set -euo pipefail

trim() { awk '{$1=$1;print}'; }

SERVICE="$(printf '%s' "${1-}" | trim)"
IMAGE_TAG="$(printf '%s' "${2-}" | trim)"
ENVIRONMENT="$(printf '%s' "${3:-dev}" | trim)"

if [[ -z "${SERVICE}" || -z "${IMAGE_TAG}" ]]; then
  echo "❌ Usage: $0 <SERVICE> <IMAGE_TAG> [ENVIRONMENT]" >&2
  exit 1
fi

# Map service names (gatewayserver -> gateway in values.yaml)
case "${SERVICE}" in
  gatewayserver)
    HELM_SERVICE="gateway"
    ;;
  *)
    HELM_SERVICE="${SERVICE}"
    ;;
esac

TAGS_FILE="06-helm/environments/${ENVIRONMENT}-env/image-tags.yaml"

echo "🔄 Updating ${HELM_SERVICE}.image.tag to ${IMAGE_TAG} in ${TAGS_FILE}"

# Configure git FIRST
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git config pull.rebase true

# Install yq
echo "📦 Installing yq..."
wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
chmod +x /usr/local/bin/yq

# Function to apply our change (used after rebase)
apply_tag_update() {
  yq eval ".${HELM_SERVICE}.image.tag = ${IMAGE_TAG}" -i "${TAGS_FILE}"
  
  # Verify the update
  if yq eval ".${HELM_SERVICE}.image.tag" "${TAGS_FILE}" | grep -q "^${IMAGE_TAG}$"; then
    echo "✅ Successfully updated ${HELM_SERVICE}.image.tag to ${IMAGE_TAG}"
    return 0
  else
    echo "❌ Failed to verify tag update" >&2
    return 1
  fi
}

# Function to sync with remote and apply our change
sync_and_update() {
  echo "📥 Syncing with remote..."
  git fetch origin main
  
  # Reset to remote state (discard any local changes)
  git reset --hard origin/main
  
  # Now apply our change
  apply_tag_update
}

# Initial sync
sync_and_update

# Check if there are changes
if git status --porcelain "${TAGS_FILE}" | grep -q .; then
  echo "📝 Changes detected, proceeding with commit"
else
  echo "ℹ️  No changes to commit (tag already set to ${IMAGE_TAG})"
  exit 0
fi

# Commit and push with retry logic
MAX_RETRIES=10
RETRY_COUNT=0
BASE_DELAY=2  # Start with 2 seconds

while true; do
  # Stage and commit
  git add "${TAGS_FILE}"
  
  # Check if commit is needed (might have been committed in previous retry)
  if git diff --cached --quiet && git diff HEAD --quiet "${TAGS_FILE}"; then
    echo "ℹ️  No changes to commit (might have been committed already)"
    # Still need to push if there's a commit
    if git log origin/main..HEAD --oneline | grep -q .; then
      echo "📤 Pushing existing commit..."
    else
      echo "✅ Already up to date"
      exit 0
    fi
  else
    echo "📝 Committing changes..."
    git commit -m "chore: update ${HELM_SERVICE} image tag to ${IMAGE_TAG} [skip ci]" || {
      echo "⚠️  Commit failed (might be no changes)"
      # Check if file already has our tag
      CURRENT_TAG=$(yq eval ".${HELM_SERVICE}.image.tag" "${TAGS_FILE}" 2>/dev/null || echo "")
      if [[ "${CURRENT_TAG}" == "${IMAGE_TAG}" ]]; then
        echo "✅ Tag already set correctly, no commit needed"
        exit 0
      fi
      exit 1
    }
  fi
  
  # Try to push
  echo "🚀 Attempting to push (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)..."
  if git push origin main; then
    echo "✅ Successfully pushed image tag update"
    exit 0
  fi
  
  # Push failed - increment retry counter
  RETRY_COUNT=$((RETRY_COUNT+1))
  
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "❌ Failed to push changes after $MAX_RETRIES retries." >&2
    echo "💡 Another job may have updated the file. Change will be picked up in the next run." >&2
    exit 1
  fi
  
  # Calculate exponential backoff with jitter (random 0-2 seconds)
  DELAY=$((BASE_DELAY * (2 ** (RETRY_COUNT - 1)) + RANDOM % 3))
  echo "⚠️  Push failed (likely due to parallel updates). Retrying in ${DELAY} seconds..."
  sleep "${DELAY}"
  
  # Sync with remote and re-apply our change
  echo "🔄 Rebasing on latest changes..."
  sync_and_update
  
  # Check if our change is still needed
  CURRENT_TAG=$(yq eval ".${HELM_SERVICE}.image.tag" "${TAGS_FILE}" 2>/dev/null || echo "")
  if [[ "${CURRENT_TAG}" == "${IMAGE_TAG}" ]]; then
    echo "✅ Tag already set correctly by another job, no action needed"
    exit 0
  fi
  
  # Reset any existing commits (we'll create a new one)
  git reset --soft origin/main 2>/dev/null || true
done