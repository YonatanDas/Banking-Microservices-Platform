#!/bin/bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
TF_DIR="05-terraform/environments/${ENVIRONMENT}"

cd "${TF_DIR}"

# 1. Generate binary plan file
terraform plan -var-file="${ENVIRONMENT}.tfvars" -out=tfplan-${ENVIRONMENT}.bin -no-color

# 2. Save a human-readable plan output (for PR summary)
terraform show -no-color tfplan-${ENVIRONMENT}.bin > tfplan-${ENVIRONMENT}.txt

# 3. Convert plan to JSON (for analysis & automation)
terraform show -json tfplan-${ENVIRONMENT}.bin > tfplan-${ENVIRONMENT}.json

echo "Terraform plan for ${ENVIRONMENT} generated successfully."