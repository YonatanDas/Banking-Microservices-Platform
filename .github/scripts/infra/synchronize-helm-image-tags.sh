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

TAGS_FILE="helm/environments/${ENVIRONMENT}-env/image-tags.yaml"

echo "🔄 Updating ${HELM_SERVICE}.image.tag to ${IMAGE_TAG} in ${TAGS_FILE}"

# Configure git FIRST
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git config pull.rebase true

# Detect current branch (works for both push and PR events)
if [ -n "${GITHUB_HEAD_REF:-}" ]; then
  # PR event - use the head ref (feature branch)
  CURRENT_BRANCH="${GITHUB_HEAD_REF}"
elif [ -n "${GITHUB_REF:-}" ]; then
  # Push event - extract branch from GITHUB_REF (refs/heads/branch-name)
  CURRENT_BRANCH="${GITHUB_REF#refs/heads/}"
else
  # Fallback to git command
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
fi

# Default to main if detection failed
CURRENT_BRANCH="${CURRENT_BRANCH:-main}"

echo "🌿 Detected branch: ${CURRENT_BRANCH}"

# Install yq
echo "📦 Installing yq..."
wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
chmod +x /usr/local/bin/yq

# Function to check if our tag is already set correctly
# Optionally checks in a specific commit (default: working directory)
check_tag_already_set() {
  local check_ref="${1:-}"  # Optional: commit ref to check (e.g., "HEAD", "origin/branch")
  local current_tag
  
  if [[ -n "${check_ref}" ]]; then
    # Check in a specific commit
    current_tag=$(git show "${check_ref}:${TAGS_FILE}" 2>/dev/null | yq eval ".${HELM_SERVICE}.image.tag" 2>/dev/null || echo "")
  else
    # Check in working directory
    current_tag=$(yq eval ".${HELM_SERVICE}.image.tag" "${TAGS_FILE}" 2>/dev/null || echo "")
  fi
  
  if [[ "${current_tag}" == "${IMAGE_TAG}" ]]; then
    if [[ -n "${check_ref}" ]]; then
      echo "✅ Tag ${HELM_SERVICE}.image.tag is already set to ${IMAGE_TAG} in ${check_ref}"
    else
      echo "✅ Tag ${HELM_SERVICE}.image.tag is already set to ${IMAGE_TAG}"
    fi
    return 0
  fi
  return 1
}

# Function to apply our change
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

# Function to sync with remote using rebase (preserves local commits)
sync_with_rebase() {
  echo "📥 Fetching latest changes from ${CURRENT_BRANCH}..."
  git fetch origin "${CURRENT_BRANCH}"
  
  # Check if we have local commits
  if git log "origin/${CURRENT_BRANCH}"..HEAD --oneline 2>/dev/null | grep -q .; then
    echo "🔄 Rebasing local commits on top of remote..."
    # We have local commits, rebase them on top of remote
    if ! git rebase "origin/${CURRENT_BRANCH}"; then
      # Rebase conflict - abort and start fresh
      echo "⚠️  Rebase conflict detected, aborting and starting fresh..."
      git rebase --abort 2>/dev/null || true
      git reset --hard "origin/${CURRENT_BRANCH}"
      return 1
    fi
  else
    # No local commits, just reset to remote
    echo "📥 No local commits, syncing with remote..."
    git reset --hard "origin/${CURRENT_BRANCH}"
  fi
  
  return 0
}

# Initial sync
echo "🔄 Initial sync with remote..."
sync_with_rebase

# Check if tag is already set in remote (before making any changes)
if check_tag_already_set "origin/${CURRENT_BRANCH}"; then
  echo "ℹ️  Tag already set correctly in remote, no action needed"
  exit 0
fi

# Apply our change
apply_tag_update

# Check if there are changes to commit
if ! git status --porcelain "${TAGS_FILE}" | grep -q .; then
  echo "ℹ️  No changes detected (tag might have been set by another process)"
  if check_tag_already_set; then
    echo "✅ Tag is already set correctly"
    exit 0
  else
    echo "⚠️  Unexpected state: file unchanged but tag not set correctly"
    exit 1
  fi
fi

# Commit and push with retry logic
MAX_RETRIES=10
RETRY_COUNT=0
BASE_DELAY=2  # Start with 2 seconds

while true; do
  # Stage the file
  git add "${TAGS_FILE}"
  
  # Check if we need to commit (file has changes)
  if git diff --cached --quiet; then
    echo "ℹ️  No staged changes (might have been committed already)"
    # Check if we have unpushed commits
    if git log "origin/${CURRENT_BRANCH}"..HEAD --oneline 2>/dev/null | grep -q .; then
      echo "📤 We have local commits, will try to push..."
    else
      # Check if tag is already set (maybe another job did it)
      if check_tag_already_set; then
        echo "✅ Tag already set correctly (likely by another job)"
        exit 0
      else
        echo "⚠️  No changes and no commits, but tag not set. Re-applying update..."
        apply_tag_update
        git add "${TAGS_FILE}"
      fi
    fi
  else
    # We have changes to commit
    echo "📝 Committing changes..."
    git commit -m "chore: update ${HELM_SERVICE} image tag to ${IMAGE_TAG} [skip ci]" || {
      echo "⚠️  Commit failed"
      # Check if tag is already set
      if check_tag_already_set; then
        echo "✅ Tag already set correctly, no commit needed"
        exit 0
      fi
      echo "❌ Commit failed and tag not set correctly" >&2
      exit 1
    }
    echo "✅ Changes committed locally"
  fi
  
  # Try to push
  echo "🚀 Attempting to push (attempt $((RETRY_COUNT+1))/$MAX_RETRIES)..."
  if git push origin "${CURRENT_BRANCH}"; then
    echo "✅ Successfully pushed image tag update"
    exit 0
  fi
  
  # Push failed - increment retry counter
  RETRY_COUNT=$((RETRY_COUNT+1))
  
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "❌ Failed to push changes after $MAX_RETRIES retries." >&2
    echo "💡 Another job may have updated the file. Checking final state..." >&2
    
    # Final check: sync and see if tag is set in remote
    sync_with_rebase || true
    if check_tag_already_set "origin/${CURRENT_BRANCH}"; then
      echo "✅ Tag is set correctly in remote (likely by another job), exiting successfully"
      exit 0
    else
      echo "❌ Tag is not set correctly in remote after all retries" >&2
      echo "💡 Current remote tag value: $(git show "origin/${CURRENT_BRANCH}:${TAGS_FILE}" 2>/dev/null | yq eval ".${HELM_SERVICE}.image.tag" 2>/dev/null || echo "unknown")" >&2
      exit 1
    fi
  fi
  
  # Calculate exponential backoff with jitter (random 0-2 seconds)
  DELAY=$((BASE_DELAY * (2 ** (RETRY_COUNT - 1)) + RANDOM % 3))
  echo "⚠️  Push failed (likely due to parallel updates). Retrying in ${DELAY} seconds..."
  sleep "${DELAY}"
  
  # Sync with remote using rebase (this preserves our local commit)
  echo "🔄 Syncing with remote before retry..."
  if ! sync_with_rebase; then
    # Rebase failed, re-apply our change
    echo "🔄 Re-applying tag update after rebase failure..."
    apply_tag_update
    git add "${TAGS_FILE}"
    # Don't commit yet, let the loop handle it
  else
    # Rebase succeeded, check if our change is still needed
    # First check if tag is set in the remote (what will be pushed)
    if check_tag_already_set "origin/${CURRENT_BRANCH}"; then
      echo "✅ Tag already set correctly in remote, no action needed"
      exit 0
    fi
    
    # Check if our commit is still there
    if git log "origin/${CURRENT_BRANCH}"..HEAD --oneline 2>/dev/null | grep -q .; then
      # We have local commits, verify they contain our tag update
      if check_tag_already_set "HEAD"; then
        echo "✅ Local commit contains correct tag, will retry push"
      else
        # Our commit doesn't have the tag set, re-apply change
        echo "⚠️  Local commit doesn't have correct tag, re-applying change..."
        apply_tag_update
        git add "${TAGS_FILE}"
        # Will commit in next iteration
      fi
    else
      # No local commits, check if working directory has the tag
      if check_tag_already_set; then
        # Tag is in working directory but not committed, we need to commit it
        echo "⚠️  Tag is set in working directory but not committed, will commit and push"
        apply_tag_update  # Ensure it's set
        git add "${TAGS_FILE}"
        # Will commit in next iteration
      else
        # Tag is not set, re-apply change
        echo "⚠️  Tag not set after rebase, re-applying change..."
        apply_tag_update
        git add "${TAGS_FILE}"
        # Will commit in next iteration
      fi
    fi
  fi
done

