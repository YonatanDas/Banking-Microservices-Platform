#!/bin/bash
set -euo pipefail
ENV="${1:-}"

curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
tfsec --version

tfsec terraform/environments/${ENV}/ --format json --out tfsec-report.json || true
tfsec terraform/environments/${ENV}/ --format sarif --out tfsec-report.sarif || true

echo "✅ tfsec scan completed." 


