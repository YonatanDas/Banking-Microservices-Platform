#!/bin/bash
set -euo pipefail

# Run Checkov
checkov -d terraform/ --framework terraform --output json --output-file checkov-report.json
checkov -d terraform/ --framework terraform --output sarif --output-file checkov-report.sarif

# Run tfsec
tfsec terraform/ --format json --out tfsec-report.json
tfsec terraform/ --format sarif --out tfsec-report.sarif

