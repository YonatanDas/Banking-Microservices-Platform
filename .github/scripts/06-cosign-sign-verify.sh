#!/usr/bin/env bash
set -euo pipefail

trim() { awk '{$1=$1;print}'; }

REGISTRY="$(printf '%s' "${1-}" | trim)"
SERVICE="$(printf '%s' "${2-}" | trim)"
GITHUB_RUN= "$(printf '%s' "${3-}" | trim)"

if [[ -z "$REGISTRY" || -z "$SERVICE" ]]; then
  echo "Usage: script <REGISTRY> <SERVICE>"
  exit 1
fi

IMAGE="${REGISTRY}/${SERVICE}:${GITHUB_RUN}"
echo "Signing image: $IMAGE"

export COSIGN_EXPERIMENTAL=1

cosign sign --yes "$IMAGE"

echo "Verifying..."
cosign verify "$IMAGE" \
  --certificate-identity "https://github.com/${GITHUB_WORKFLOW_REF}" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"
  
echo "Cosign signing completed."