#!/bin/bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
OUTPUT_FILE="${2:-tfplan-${ENVIRONMENT}}"
TF_DIR="terraform/environments/${ENVIRONMENT}"

cd "${TF_DIR}"
terraform init
terraform plan -var-file="${ENVIRONMENT}.tfvars" -out="${OUTPUT_FILE}"
terraform show -json "${OUTPUT_FILE}" > "${OUTPUT_FILE}.json"

