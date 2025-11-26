# CI/CD with GitHub Actions

## Purpose in this project

GitHub Actions workflows automate the entire software delivery lifecycle: **building, testing, scanning, signing, and deploying** microservices and infrastructure. All workflows use **OIDC-based authentication** (no long-lived credentials) and integrate with AWS ECR, EKS, and S3 for artifact storage.

## Folder structure overview

```
.github/
├── workflows/
│   ├── Microservice-Ci.yaml        # Microservices CI/CD pipeline
│   ├── terraform-validate.yaml     # Terraform validation & security scanning
│   ├── terraform-plan.yaml         # Terraform plan generation
│   └── terraform-apply.yaml        # Terraform apply with approval gates
├── scripts/
│   ├── 01-test-java.sh             # Maven lint, test, coverage
│   ├── 02-trivy-fs-scan.sh         # Trivy filesystem vulnerability scan
│   ├── 03-setup-buildx-cache.sh    # Docker Buildx cache setup
│   ├── 04a-build-image.sh          # Multi-arch Docker image build
│   ├── 04b-push-image.sh           # Push to ECR
│   ├── 05-docker-cache-cleanup.sh   # Cache cleanup
│   ├── 06-cosign-sign-verify.sh    # Cosign keyless signing & verification
│   ├── 07-image-scan-sbom.sh       # Trivy image scan + SBOM generation
│   ├── 08-artifact_collect_and_s3.sh  # Upload artifacts to S3
│   ├── 09-checkov-security-scan.sh # Checkov IaC security scan
│   ├── 12-tfsec-security-scan.sh   # tfsec IaC security scan
│   ├── 13-terraform-plan.sh        # Terraform plan generation
│   └── 14-update-helm-values.sh    # Helm values update helper
└── actions/
    ├── env-setup/
    │   └── action.yaml              # AWS OIDC + ECR login composite action
    ├── caching/
    │   └── action.yaml              # Docker cache management
    └── terraform-setup/
        └── action.yaml              # Terraform installation & caching
```

**Key entry points**: `.github/workflows/*.yaml` (triggered on push/PR to `main`)

## How it works / design

### Microservices CI/CD pipeline (`Microservice-Ci.yaml`)

**Trigger**: Push/PR to `main` branch when `accounts/`, `cards/`, `loans/`, or `gatewayserver/` directories change

**Pipeline stages**:
1. **Service detection**: `dorny/paths-filter` identifies changed services
2. **Lint & test**: Maven lint, unit tests, code coverage (parallelized per service)
3. **Trivy FS scan**: Filesystem vulnerability scanning before image build
4. **Build & push**: Docker Buildx multi-arch builds, push to ECR with tag `github.run_number`
5. **Image security**: Trivy image scan, SBOM generation (CycloneDX), Cosign keyless signing
6. **Artifact archival**: Uploads test reports, scan results, SBOMs, build metadata to S3

**OIDC authentication**: Uses `github-actions-eks-ecr-role` (created by Terraform `iam/github_oidc` module) for ECR push and S3 upload

### Terraform workflows

**Three-stage pipeline**:
1. **`terraform-validate.yaml`**: Runs `terraform fmt`, `validate`, Checkov, and tfsec scans; archives results to S3
2. **`terraform-plan.yaml`**: Generates Terraform plans (binary, text, JSON) for all environments; stores in S3 for review
3. **`terraform-apply.yaml`**: Applies Terraform with manual approval gate; requires uploaded plan artifacts for staging/prod

**Security scanning**: Checkov and tfsec scan Terraform code for misconfigurations, insecure defaults, and compliance violations

**Approval gates**: Production applies require manual approval and branch protection; dev can auto-approve

### Composite actions

- **`env-setup`**: Configures AWS credentials via OIDC, logs into ECR
- **`caching`**: Manages Docker Buildx cache for faster builds
- **`terraform-setup`**: Installs Terraform version, caches for reuse

## Key highlights

- **OIDC-based authentication**: No long-lived AWS credentials; short-lived tokens via GitHub OIDC provider
- **Security scanning**: Trivy scans (filesystem + image), Checkov/tfsec IaC scanning, Cosign image signing, SBOM generation
- **Artifact integrity**: All build artifacts (tests, scans, SBOMs, Terraform plans) archived to S3 for auditability
- **Parallel execution**: Service builds run in parallel matrix strategy
- **Multi-arch support**: Docker Buildx builds for `linux/amd64` and `linux/arm64`
- **Approval gates**: Terraform applies require manual approval for staging/prod, preventing accidental infrastructure changes
- **Change detection**: Path-based filtering only builds changed services, reducing CI/CD time and cost

## How to use / extend

### Trigger microservices CI

Push changes to `accounts/`, `cards/`, `loans/`, or `gatewayserver/` directories:
```bash
git commit -m "Update accounts service"
git push origin main
```

### Run Terraform validation

Workflow auto-triggers on Terraform file changes, or manually trigger via GitHub Actions UI.

### Approve Terraform apply

1. **Plan stage**: `terraform-plan` workflow generates and uploads plans
2. **Review plans**: Download plans from S3 or view in workflow artifacts
3. **Approve apply**: `terraform-apply` workflow requires manual approval; click "Review deployments" in GitHub Actions UI

### Add a new service to CI

1. Add service directory to `paths` filter in `Microservice-Ci.yaml`:
```yaml
paths:
  - "new-service/**"
```
2. Add service to `dorny/paths-filter` filters
3. Add service to matrix strategy

### Modify security scanning

Edit `.github/scripts/02-trivy-fs-scan.sh` or `09-checkov-security-scan.sh` to adjust scan severity levels or add custom policies.

### View artifacts

All artifacts uploaded to S3 bucket `my-ci-artifacts55` under prefix `Ci-Artifacts/`. Access via AWS Console or CLI.

