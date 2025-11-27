# Terraform Infrastructure as Code

## Purpose in this project

Terraform provisions and manages all AWS infrastructure for the multi-environment banking platform. It creates EKS clusters, VPCs, RDS databases, ECR repositories, IAM roles (including IRSA), and installs critical Kubernetes operators (Argo CD, External Secrets Operator, Kyverno, ALB Controller) via Helm releases.

## Folder structure overview

```
05-terraform/
├── environments/
│   ├── dev/          # Development environment stack
│   ├── stag/         # Staging environment stack
│   └── prod/         # Production environment stack
│       ├── main.tf           # Environment-specific resource composition
│       ├── variables.tf     # Input variables
│       ├── backend.tf        # Remote state (S3 + DynamoDB)
│       └── *.tfvars          # Environment-specific values
└── modules/
    ├── vpc/           # VPC, subnets, route tables, security groups
    ├── eks/           # EKS cluster, node groups, OIDC provider, operators
    ├── ecr/           # ECR repositories per service
    ├── rds/           # RDS PostgreSQL instances
    ├── secrets/       # AWS Secrets Manager integration
    ├── iam/           # IAM roles (IRSA, GitHub OIDC, ALB Controller, ESO)
    └── monitoring/    # S3 buckets and IAM for Loki log storage
```

**Key entry points**: `05-terraform/environments/{dev,stag,prod}/main.tf`

## How it works / design

### Module-based architecture

Each environment (`dev`, `stag`, `prod`) composes reusable Terraform modules to provision:
- **VPC module**: Creates VPC with public/private subnets across multiple AZs, security groups for EKS and RDS
- **EKS module**: Provisions EKS cluster with managed node groups, installs Argo CD, External Secrets Operator, Kyverno, and AWS Load Balancer Controller via Helm
- **ECR module**: Creates container registries for each microservice (`accounts`, `cards`, `loans`, `gatewayserver`)
- **RDS module**: Deploys PostgreSQL in private subnets with automated backups
- **Secrets module**: Stores RDS credentials in AWS Secrets Manager
- **IAM modules**: Creates IRSA roles for services (RDS access), External Secrets Operator, GitHub Actions (OIDC), ALB Controller, and Argo CD Image Updater

### Remote state management

Each environment uses S3 backend with DynamoDB locking:
- **State isolation**: Separate state files per environment prevent cross-environment drift
- **State locking**: DynamoDB table prevents concurrent modifications
- **Backend configuration**: Defined in `05-terraform/environments/*/backend.tf`

### Multi-environment pattern

- **Environment-specific variables**: `*.tfvars` files contain CIDR blocks, instance sizes, DB configurations
- **Shared modules**: All environments use the same module codebase, ensuring consistency
- **Conditional logic**: Modules accept environment flags for resource tagging and naming

## Key highlights

- **Modularity and reusability**: Single module codebase supports dev/staging/prod with environment-specific values
- **State management**: Remote state in S3 with DynamoDB locking for safe concurrent operations
- **Security by design**: IRSA roles created per service with least-privilege policies, GitHub OIDC eliminates long-lived credentials
- **Operator installation**: Kubernetes operators (Argo CD, ESO, Kyverno) installed via Terraform Helm provider
- **Network isolation**: VPC module creates private subnets for RDS and EKS nodes, public subnets only for ALB
- **Automated validation**: GitHub Actions workflows enforce `terraform fmt`, `validate`, and security scanning (Checkov, tfsec) before apply

## How to use / extend

### Provision an environment

```bash
cd 05-terraform/environments/dev
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### Add a new environment

1. Copy `05-terraform/environments/dev/` to `05-terraform/environments/<new-env>/`
2. Update `backend.tf` with new S3 bucket/key and DynamoDB table
3. Create `<new-env>.tfvars` with environment-specific values
4. Run `terraform init` and `terraform plan`

### Add a new microservice

1. Add service name to `module.ecr.service_names` list in `environments/*/main.tf`
2. Add IRSA role creation in `locals.microservices` and `module.rds_access_role` block
3. Add ECR repository ARN to `module.argocd_image_updater_role.ecr_repository_arns`

### Modify infrastructure

- **VPC changes**: Edit `05-terraform/modules/vpc/main.tf`
- **EKS configuration**: Edit `05-terraform/modules/eks/main.tf` and `variables.tf`
- **IAM policies**: Edit `05-terraform/modules/iam/*/main.tf`

All changes should be validated via GitHub Actions `terraform-validate` workflow before applying.

