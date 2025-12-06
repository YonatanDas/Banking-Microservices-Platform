# Terraform Infrastructure as Code

Terraform provisions and manages all AWS infrastructure for the multi-environment banking platform. It creates EKS clusters, VPCs, RDS databases, ECR repositories, IAM roles (including IRSA), and installs critical Kubernetes operators (Argo CD, External Secrets Operator, Kyverno, ALB Controller) via Helm releases.


## Overall Design

**What This Manages:**
- **VPC**: Public/private subnets across multiple AZs, NAT Gateway, Internet Gateway, route tables
- **EKS**: Kubernetes clusters with managed node groups, OIDC provider
- **RDS**: PostgreSQL databases in private subnets with automated backups
- **ECR**: Container registries for each microservice
- **IAM**: IRSA roles for services, GitHub OIDC roles, ALB Controller role, ESO role, Argo CD Image Updater role
- **Secrets**: AWS Secrets Manager integration for RDS credentials
- **Monitoring**: S3 buckets and IAM roles for Loki log storage
- **Kubernetes Operators**: Argo CD, External Secrets Operator, Kyverno, AWS Load Balancer Controller (installed via Helm)

**Module-Based Architecture**: Reusable Terraform modules in `modules/` directory. Environment-specific configurations in `environments/{dev,stag,prod}/` compose these modules.

## Remote State

**S3 Backend**: Each environment stores Terraform state in S3:
- **Bucket**: `banking-terraform-state-18.10.25` (configurable)
- **Key**: `envs/{environment}/terraform.tfstate` (separate state per environment)
- **Region**: `us-east-1`
- **Encryption**: Enabled (`encrypt: true`)

**DynamoDB Locking**: State locking via DynamoDB table:
- **Table**: `terraform-locks`
- **Prevents**: Concurrent modifications to the same state file

**State Separation**: Each environment (dev/stag/prod) has a separate state file, preventing cross-environment drift and enabling independent operations.

## Modules

**Module Structure**: Small, focused modules in `modules/` directory:
- `vpc/` - VPC, subnets, route tables, security groups, NAT Gateway
- `eks/` - EKS cluster, managed node groups, OIDC provider, Kubernetes operators (Helm releases)
- `rds/` - RDS PostgreSQL instances with automated backups
- `ecr/` - ECR repositories per microservice
- `secrets/` - AWS Secrets Manager secrets for RDS credentials
- `iam/` - IAM roles and policies:
  - `github_oidc/` - GitHub Actions OIDC provider and roles
  - `node_role/` - EKS node IAM role
  - `karpenter_controller_role/` - Karpenter controller IAM role
  - `alb_controller_role/` - AWS Load Balancer Controller role
  - `external_secrets_role/` - External Secrets Operator role
  - `argocd_image_updater_role/` - Argo CD Image Updater role
  - `rds_access_role/` - IRSA roles for service RDS access
  - `cluster_role/` - Cluster-level IAM roles
  - `eks_users/` - IAM users for EKS access (optional)
- `monitoring/` - S3 buckets and IAM roles for Loki log storage

**Module Reuse**: All environments use the same module codebase with environment-specific variable values, ensuring consistency across environments.

**Best Practices**:
- **Small, Focused Modules**: Each module has a single responsibility
- **Clear Input/Output Variables**: Well-documented variables and outputs
- **No Secrets in Code**: Secrets stored in AWS Secrets Manager, referenced via variables
- **DRY Principle**: Shared modules eliminate duplication

## Environments

**Environment Structure**: Separate folders per environment:
- `environments/dev/` - Development environment
- `environments/stag/` - Staging environment
- `environments/prod/` - Production environment

**Environment Configuration**: Each environment has:
- `main.tf` - Composes modules with environment-specific values
- `variables.tf` - Input variable definitions
- `backend.tf` - Remote state configuration (S3 + DynamoDB)
- `provider.tf` - AWS provider configuration
- `versions.tf` - Terraform and provider version constraints
- `{env}.tfvars` - Environment-specific variable values (CIDR blocks, instance sizes, DB configs)

**How Environments Are Applied**:
- **Manual**: `terraform apply -var-file={env}.tfvars` in each environment directory
- **GitHub Actions**: `infra-terraform-apply.yaml` workflow with environment selection
- **State Isolation**: Each environment has separate state file, preventing cross-environment changes

## Security & Best Practices

### Network Security

**Private Subnets**: RDS instances and EKS nodes deployed in private subnets (no direct internet access). Only NAT Gateway and public subnets have internet gateway access.

**Security Groups**: Restrictive security group rules:
- EKS cluster security group allows only necessary traffic
- RDS security group allows access only from EKS node security group
- ALB security group allows HTTP/HTTPS from internet

**VPC Isolation**: Each environment has its own VPC with environment-specific CIDR blocks.

### IAM Security

**IRSA (IAM Roles for Service Accounts)**: Each microservice has a dedicated IAM role with least-privilege permissions:
- RDS access roles scoped to specific database instances
- No long-lived credentials in pods

**GitHub OIDC**: CI/CD uses OIDC provider instead of access keys:
- `github-actions-eks-ecr-role` - For ECR push/pull
- `github-actions-terraform-role` - For Terraform state access

**Least-Privilege IAM**: All IAM roles follow least-privilege principle:
- ECR roles restricted to specific repository ARNs
- RDS access roles restricted to specific database instances
- ESO role has access only to required secrets

### Secrets Management

![External Secrets Operator Diagram](../../docs/diagrams/ESO-diagram.png)

**AWS Secrets Manager**: RDS credentials stored in Secrets Manager, not in Terraform state or Git.

**External Secrets Operator**: ESO syncs secrets from Secrets Manager to Kubernetes, eliminating secrets in Git.

**No Secrets in Code**: `.tfvars` files contain account IDs and resource names, but not sensitive credentials.

### Data Protection

**RDS Encryption**: RDS instances use encryption at rest (AWS-managed encryption).

**Backup Retention**: Automated backups configured with retention periods (environment-specific).

**Deletion Protection**: Production and staging RDS instances have deletion protection enabled.

### Infrastructure Hardening

**EKS Security**: 
- Private endpoint (configurable per environment)
- OIDC provider for IRSA
- Managed node groups with security group restrictions

**Operator Installation**: Kubernetes operators installed via Terraform Helm provider, ensuring infrastructure-as-code consistency.

## Usage

### Provision an Environment

```bash
cd infra/terraform/environments/dev
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### Add a New Environment

1. Copy `environments/dev/` to `environments/{new-env}/`
2. Update `backend.tf` with new S3 key: `envs/{new-env}/terraform.tfstate`
3. Create `{new-env}.tfvars` with environment-specific values
4. Run `terraform init` and `terraform plan`

### Add a New Microservice

1. Add service name to `module.ecr.service_names` list in `environments/*/main.tf`
2. Add IRSA role creation in `locals.microservices` and `module.rds_access_role` block
3. Add ECR repository ARN to `module.argocd_image_updater_role.ecr_repository_arns`

### Modify Infrastructure

- **VPC changes**: Edit `modules/vpc/main.tf`
- **EKS configuration**: Edit `modules/eks/main.tf` and `variables.tf`
- **IAM policies**: Edit `modules/iam/*/main.tf`

All changes should be validated via GitHub Actions `infra-terraform-validate.yaml` workflow before applying.
