# CI/CD Workflows

GitHub Actions workflows implementing automated CI/CD pipelines for microservices and infrastructure.

## Pipeline Overview

### Service CI/CD Pipelines (`applications-*.yaml`)

![Services Workflow Diagram](../../docs/diagrams/Services-Workflow.png)

Each microservice (accounts, cards, loans, gateway) has a dedicated workflow triggered on code changes:

**Main Stages:**
1. **Test**: Maven build, unit tests, code coverage (JaCoCo)
2. **Security Scan (Filesystem)**: Trivy filesystem vulnerability scanning
3. **Build**: Docker image build with Buildx caching
4. **Security Scan (Image)**: Trivy container image scanning, SBOM generation
5. **Sign & Push**: Cosign image signing, ECR push
6. **Deploy**: Argo CD sync to dev environment (optional promotion to staging/production)

**Security Scanning:**
- **Trivy**: Filesystem and container image vulnerability scanning
- **SBOM Generation**: Software Bill of Materials (SPDX format) for each image
- **Artifact Archival**: All scan reports and SBOMs uploaded to S3

**Image Signing:**
- **Cosign**: All container images signed before ECR push
- **Verification**: Image signatures verified during deployment

**Deployment Promotion:**
- Manual workflow dispatch with options to promote to staging/production
- Deployment validation and health checks before promotion

### Terraform Workflows

![Terraform Validation Workflow](../../docs/diagrams/Terraform-Validate.png)

**`infra-terraform-validate.yaml`**
- **Format Check**: `terraform fmt -check` validation
- **Terraform Validate**: Syntax and configuration validation per environment (dev/stag/prod)
- **Security Scanning**: 
  - Checkov: Terraform security policy scanning
  - tfsec: Terraform security analysis
- **Artifact Collection**: All reports uploaded to S3

**`infra-terraform-plan.yaml`**
- **Change Detection**: Detects Terraform changes per environment
- **Terraform Plan**: Generates execution plan with PR comments
- **Security Scanning**: Checkov and tfsec scans on plan output
- **Artifact Archival**: Plans and scan reports stored in S3

**`infra-terraform-apply.yaml`**
- **Manual Trigger**: Requires workflow dispatch with environment selection
- **Terraform Apply**: Executes infrastructure changes
- **State Management**: Uses S3 backend with DynamoDB locking

**Environment Handling:**
- Separate workflows/inputs per environment (dev/stag/prod)
- Remote state stored in S3 with environment-specific keys
- State locking via DynamoDB table

![Terraform Plan and Apply Workflow](../../docs/diagrams/Terraform-Plan-Apply.png)

### Service Discovery (`service-discovery.yaml`)

**Auto-Detection & Generation:**
- **Detection**: Scans `applications/` directory for new services (services without workflow files)
- **Auto-Generation**: For each new service, generates:
  - Helm chart skeleton in `helm/bankingapp-services/{service}/`
  - Dedicated workflow file `.github/workflows/applications-{service}.yaml`
  - Updates environment charts to include new service
- **Auto-Commit**: Commits generated files back to repository

**How It Works:**
1. Workflow checks for services in `applications/` without corresponding workflow files
2. For each new service, runs `setup-new-service.sh` script
3. Script generates Helm chart from template and workflow from template
4. Changes are committed and pushed automatically

## Authentication & Security

**OIDC Authentication:**
- GitHub Actions uses OIDC to assume AWS IAM roles
- No long-lived AWS access keys stored in secrets
- Roles: `github-actions-eks-ecr-role` (for ECR), `github-actions-terraform-role` (for Terraform)

**Artifact Management:**
- All build artifacts, scan reports, and SBOMs uploaded to S3
- S3 bucket and prefix configurable via secrets
- Artifacts organized by workflow name and commit SHA

## Workflow Files

- `applications-accounts.yaml` - Accounts service CI/CD
- `applications-cards.yaml` - Cards service CI/CD
- `applications-loans.yaml` - Loans service CI/CD
- `applications-gateway.yaml` - Gateway service CI/CD
- `deploy-applications.yaml` - Multi-service deployment orchestration
- `service-discovery.yaml` - New service auto-detection and generation
- `infra-terraform-validate.yaml` - Terraform validation and security scanning
- `infra-terraform-plan.yaml` - Terraform planning with PR comments
- `infra-terraform-apply.yaml` - Terraform infrastructure deployment

