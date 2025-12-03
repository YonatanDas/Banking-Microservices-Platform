#!/usr/bin/env bash
set -euo pipefail

IMAGE_URI="$1"
OUTPUT_DIR="${2:-trivy_reports}"
FAIL_ON_CRITICAL="${3:-true}"

mkdir -p "${OUTPUT_DIR}"

echo "🔍 Running Trivy vulnerability scan on: ${IMAGE_URI}"

# 1. Vulnerability Scan (Table + JSON)
echo "📄 Generating vulnerability report..."
trivy image \
  --severity HIGH,CRITICAL \
  --format json \
  --output "${OUTPUT_DIR}/vuln-report.json" \
  "${IMAGE_URI}"

trivy image \
  --severity HIGH,CRITICAL \
  --format table \
  --output "${OUTPUT_DIR}/vuln-report.txt" \
  "${IMAGE_URI}"

echo "📦 Generating SBOM reports..."

# 2. SBOM – CycloneDX JSON
trivy image \
  --format cyclonedx \
  --output "${OUTPUT_DIR}/sbom-cyclonedx.json" \
  "${IMAGE_URI}"

# 3. SBOM – SPDX JSON
trivy image \
  --format spdx-json \
  --output "${OUTPUT_DIR}/sbom-spdx.json" \
  "${IMAGE_URI}"

echo "✅ Trivy scan completed. Reports saved in: ${OUTPUT_DIR}"

# Fail pipeline on CRITICAL vulns if enabled
if [[ "${FAIL_ON_CRITICAL}" == "true" ]]; then
    if jq '.Results[].Vulnerabilities | map(select(.Severity == "CRITICAL")) | length' "${OUTPUT_DIR}/vuln-report.json" | grep -q '[1-9]'; then
        echo "❌ Critical vulnerabilities found! Failing job."
        exit 1
    else
        echo "✅ No critical vulnerabilities found."
    fi
fi

