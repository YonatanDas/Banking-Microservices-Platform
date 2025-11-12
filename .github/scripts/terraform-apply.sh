#!/bin/bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
PLAN_FILE="${2:-tfplan-${ENVIRONMENT}}"
TF_DIR="terraform/environments/${ENVIRONMENT}"

cd "${TF_DIR}"
terraform init
terraform validate
terraform apply "${PLAN_FILE}"
terraform output -json > "terraform-output-${ENVIRONMENT}.json"

