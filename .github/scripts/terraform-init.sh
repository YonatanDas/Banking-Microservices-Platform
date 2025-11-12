#!/bin/bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
TF_DIR="terraform/environments/${ENVIRONMENT}"

cd "${TF_DIR}"
terraform init

