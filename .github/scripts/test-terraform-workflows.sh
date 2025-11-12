#!/bin/bash
set -euo pipefail

# Test Terraform CI/CD Workflows
# This script helps test the Terraform workflows locally and in GitHub Actions

ENVIRONMENT="${1:-dev}"
ACTION="${2:-help}"

echo "🔧 Terraform CI/CD Workflow Testing Script"
echo "=========================================="
echo ""

case "$ACTION" in
  help)
    echo "Usage: $0 [ENVIRONMENT] [ACTION]"
    echo ""
    echo "Environments: dev, stag, prod"
    echo ""
    echo "Actions:"
    echo "  help              - Show this help message"
    echo "  validate-format   - Test Terraform formatting"
    echo "  validate-syntax   - Test Terraform validation"
    echo "  security-scan     - Run security scans (Checkov, tfsec)"
    echo "  plan              - Generate Terraform plan"
    echo "  plan-dry-run      - Dry run plan (no AWS calls)"
    echo "  init              - Initialize Terraform"
    echo "  check-backend     - Check S3 backend and DynamoDB table"
    echo "  test-scripts      - Test helper scripts"
    echo ""
    echo "Examples:"
    echo "  $0 dev validate-format"
    echo "  $0 dev plan"
    echo "  $0 stag security-scan"
    ;;
    
  validate-format)
    echo "📝 Testing Terraform Formatting..."
    echo ""
    cd terraform/environments/$ENVIRONMENT
    terraform fmt -check -recursive ../..
    if [ $? -eq 0 ]; then
      echo "✅ Formatting is correct"
    else
      echo "❌ Formatting issues found. Run 'terraform fmt -recursive' to fix."
      exit 1
    fi
    ;;
    
  validate-syntax)
    echo "🔍 Testing Terraform Validation..."
    echo ""
    cd terraform/environments/$ENVIRONMENT
    terraform init
    terraform validate
    if [ $? -eq 0 ]; then
      echo "✅ Validation passed"
    else
      echo "❌ Validation failed"
      exit 1
    fi
    ;;
    
  security-scan)
    echo "🔒 Running Security Scans..."
    echo ""
    
    # Check if Checkov is installed
    if ! command -v checkov &> /dev/null; then
      echo "⚠️  Checkov not found. Installing..."
      pip install checkov
    fi
    
    # Check if tfsec is installed
    if ! command -v tfsec &> /dev/null; then
      echo "⚠️  tfsec not found. Installing..."
      curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
    fi
    
    echo "Running Checkov..."
    checkov -d terraform/ --framework terraform --output json --output-file-path checkov-report.json || true
    checkov -d terraform/ --framework terraform --output sarif --output-file-path checkov-report.sarif || true
    
    echo "Running tfsec..."
    tfsec terraform/ --format json --out tfsec-report.json || true
    tfsec terraform/ --format sarif --out tfsec-report.sarif || true
    
    echo "✅ Security scans completed"
    echo "Reports generated:"
    ls -la checkov-report.* tfsec-report.* 2>/dev/null || echo "No reports generated"
    ;;
    
  plan)
    echo "📋 Generating Terraform Plan..."
    echo ""
    cd terraform/environments/$ENVIRONMENT
    terraform init
    terraform plan -var-file="${ENVIRONMENT}.tfvars" -out=tfplan-${ENVIRONMENT}
    terraform show -json tfplan-${ENVIRONMENT} > tfplan-${ENVIRONMENT}.json
    echo "✅ Plan generated: tfplan-${ENVIRONMENT}"
    ;;
    
  plan-dry-run)
    echo "📋 Generating Terraform Plan (Dry Run - No AWS calls)..."
    echo ""
    cd terraform/environments/$ENVIRONMENT
    # This will still make AWS calls, but we can validate the configuration
    terraform init -backend=false
    terraform validate
    echo "✅ Configuration validated (no plan generated without backend)"
    ;;
    
  init)
    echo "🚀 Initializing Terraform..."
    echo ""
    cd terraform/environments/$ENVIRONMENT
    terraform init
    echo "✅ Terraform initialized"
    ;;
    
  check-backend)
    echo "🔍 Checking Terraform Backend..."
    echo ""
    
    # Check S3 bucket
    echo "Checking S3 bucket: banking-terraform-state-18.10.25"
    if aws s3 ls s3://banking-terraform-state-18.10.25 &> /dev/null; then
      echo "✅ S3 bucket exists"
    else
      echo "❌ S3 bucket does not exist"
      echo "Create it with:"
      echo "  aws s3 mb s3://banking-terraform-state-18.10.25 --region us-east-1"
    fi
    
    # Check DynamoDB table
    echo "Checking DynamoDB table: terraform-locks"
    if aws dynamodb describe-table --table-name terraform-locks --region us-east-1 &> /dev/null; then
      echo "✅ DynamoDB table exists"
    else
      echo "❌ DynamoDB table does not exist"
      echo "Create it with:"
      echo "  aws dynamodb create-table --table-name terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1"
    fi
    ;;
    
  test-scripts)
    echo "🧪 Testing Helper Scripts..."
    echo ""
    
    # Test terraform-init.sh
    echo "Testing terraform-init.sh..."
    if [ -f ".github/scripts/terraform-init.sh" ]; then
      chmod +x .github/scripts/terraform-init.sh
      .github/scripts/terraform-init.sh $ENVIRONMENT
      echo "✅ terraform-init.sh works"
    else
      echo "❌ terraform-init.sh not found"
    fi
    
    # Test terraform-plan.sh
    echo "Testing terraform-plan.sh..."
    if [ -f ".github/scripts/terraform-plan.sh" ]; then
      chmod +x .github/scripts/terraform-plan.sh
      echo "✅ terraform-plan.sh exists (not running to avoid AWS calls)"
    else
      echo "❌ terraform-plan.sh not found"
    fi
    
    # Test terraform-apply.sh
    echo "Testing terraform-apply.sh..."
    if [ -f ".github/scripts/terraform-apply.sh" ]; then
      chmod +x .github/scripts/terraform-apply.sh
      echo "✅ terraform-apply.sh exists (not running to avoid infrastructure changes)"
    else
      echo "❌ terraform-apply.sh not found"
    fi
    
    # Test terraform-security-scan.sh
    echo "Testing terraform-security-scan.sh..."
    if [ -f ".github/scripts/terraform-security-scan.sh" ]; then
      chmod +x .github/scripts/terraform-security-scan.sh
      echo "✅ terraform-security-scan.sh exists (not running to avoid long execution)"
    else
      echo "❌ terraform-security-scan.sh not found"
    fi
    ;;
    
  *)
    echo "❌ Unknown action: $ACTION"
    echo "Run '$0 help' for usage information"
    exit 1
    ;;
esac

echo ""
echo "✅ Test completed"

