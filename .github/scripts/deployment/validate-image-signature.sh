#!/usr/bin/env bash
set -euo pipefail

# Usage: validate-image-signature.sh <REGISTRY> <SERVICE> <IMAGE_TAG>
# Validates that a container image has a valid Cosign signature

REGISTRY="${1}"
SERVICE="${2}"
IMAGE_TAG="${3}"

if [[ -z "${REGISTRY}" || -z "${SERVICE}" || -z "${IMAGE_TAG}" ]]; then
  echo "❌ Usage: $0 <REGISTRY> <SERVICE> <IMAGE_TAG>" >&2
  exit 1
fi

IMAGE="${REGISTRY}/${SERVICE}:${IMAGE_TAG}"

echo "🔐 Validating Cosign signature for image: ${IMAGE}"

# Check if Cosign is installed
if ! command -v cosign &> /dev/null; then
  echo "📦 Installing Cosign..."
  wget -qO /usr/local/bin/cosign https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
  chmod +x /usr/local/bin/cosign
fi

export COSIGN_EXPERIMENTAL=1

# Verify the signature
echo "🔍 Verifying signature..."
if cosign verify "${IMAGE}" \
  --certificate-identity-regexp ".*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" > /dev/null 2>&1; then
  echo "✅ Image signature verified successfully"
  exit 0
else
  echo "❌ Image signature verification failed!"
  echo "⚠️  Image ${IMAGE} does not have a valid Cosign signature"
  exit 1
fi

