#!/usr/bin/env bash
set -euo pipefail

trim() { awk '{$1=$1;print}'; }

SERVICE="$(printf '%s' "${1-}" | trim)"
IMAGE_TAG="$(printf '%s' "${2-}" | trim)"
ENVIRONMENT="${3:-dev}"

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

# Check if file exists, create if not
if [[ ! -f "${TAGS_FILE}" ]]; then
  echo "📝 Creating ${TAGS_FILE}..."
  mkdir -p "$(dirname "${TAGS_FILE}")"
  cat > "${TAGS_FILE}" <<EOF
accounts:
  image:
    tag: 10
cards:
  image:
    tag: 10
loans:
  image:
    tag: 10
gateway:
  image:
    tag: 10
EOF
fi

echo "📦 Installing yq..."
wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
chmod +x /usr/local/bin/yq


# Update the tag
yq eval ".${HELM_SERVICE}.image.tag = \"${IMAGE_TAG}\"" -i "${TAGS_FILE}"

# Verify the update
if yq eval ".${HELM_SERVICE}.image.tag" "${TAGS_FILE}" | grep -q "^${IMAGE_TAG}$"; then
  echo "✅ Successfully updated ${HELM_SERVICE}.image.tag to ${IMAGE_TAG}"
else
  echo "❌ Failed to verify tag update" >&2
  exit 1
fi

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git config pull.rebase true


# Check if there are changes (compare against HEAD, handles both tracked and untracked files)
if git status --porcelain "${TAGS_FILE}" | grep -q .; then
  echo "📝 Changes detected, proceeding with commit"
else
  echo "ℹ️  No changes to commit (tag already set to ${IMAGE_TAG})"
  exit 0
fi

# Commit and push
echo "📝 Committing changes..."
git add "${TAGS_FILE}"
git commit -m "chore: update ${HELM_SERVICE} image tag to ${IMAGE_TAG} [skip ci]" || {
  echo "⚠️  Commit failed (might be no changes or already committed)"
  exit 0
}

echo "🚀 Pushing to repository..."
git pull --rebase origin main
git push || {
  echo "⚠️  Push failed. This might be expected if running in a PR." >&2
  exit 1
}

echo "✅ Successfully updated and pushed image tag"