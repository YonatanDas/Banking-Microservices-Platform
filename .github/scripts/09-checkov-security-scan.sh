#!/bin/bash
set -euo pipefail
ENV="${1:-}"

pip install checkov
checkov --version

# Run Checkov
checkov -d terraform/environments/${ENV}/ --framework terraform --quiet --output sarif --output-file-path checkov-report.json || true
checkov -d terraform/environments/${ENV}/ --framework terraform --quiet --output sarif --output-file-path checkov-report.sarif || true

echo "✅ Checkov scan completed."

