############################################
# VPC
############################################
module "vpc" {
  source               = "../../modules/vpc"
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  cluster_name         = var.cluster_name
  eks_node_sg_id       = module.eks.node_sg_id
}

############################################
# ECR Repositories
############################################
module "ecr" {
  source        = "../../modules/ecr"
  service_names = var.microservices
  environment   = var.environment
  project_name  = var.project_name
}

############################################
# IAM Roles
############################################
module "iam_cluster_role" {
  source      = "../../modules/iam/cluster_role"
  name_prefix = var.name_prefix != "" ? var.name_prefix : "platform"
}

module "iam_node_role" {
  source      = "../../modules/iam/node_role"
  name_prefix = var.name_prefix != "" ? var.name_prefix : "platform"
}

############################################
# EKS Cluster
############################################
module "eks" {
  source = "../../modules/eks"

  # identifiers
  cluster_name = var.cluster_name
  environment  = var.environment
  region       = var.aws_region

  # networking
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets

  # IAM
  cluster_role_arn        = module.iam_cluster_role.eks_cluster_role_arn
  alb_controller_role_arn = module.alb_controller_role.alb_controller
  node_role_arn           = module.iam_node_role.eks_node_role_arn
  # node group settings
  node_instance_type    = var.node_instance_type
  node_desired_capacity = var.node_desired_capacity
  node_min_size         = var.node_min_size
  node_max_size         = var.node_max_size

}

############################################
# RDS Database Instance
############################################
module "rds" {
  source = "../../modules/rds"

  environment = var.environment
  subnet_ids  = module.vpc.private_subnets
  db_engine   = "postgres"

  db_username = var.db_username
  db_password = random_password.db.result
  db_name     = "${var.environment}_${var.db_name_suffix}"

  db_instance_class = var.db_instance_class
  db_sg_id          = module.vpc.rds_sg_id

  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
}


############################################
# Secrets Manager
############################################
# Generate a strong DB password once per environment
resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "_%-!#$&*+-=<>?^~"
}

# Create DB credentials secret
module "secrets" {
  source      = "../../modules/secrets"
  environment = var.environment
  db_username = var.db_username
  db_password = random_password.db.result
  db_endpoint = module.rds.db_endpoint
  db_name     = var.db_name
  secret_name = "${var.environment}-db-credentials"
}


############################################
# IAM Role for RDS Access via IRSA
############################################
locals {
  # Build microservices map from service_registry, filtering only services that need RDS access
  microservices_with_rds = {
    for k, v in var.service_registry : k => {
      sa_name = v.service_account_name
    } if v.needs_rds_access
  }
}

module "rds_access_role" {
  source               = "../../modules/iam/rds_access_role"
  for_each             = local.microservices_with_rds
  environment          = var.environment
  oidc_provider_arn    = module.eks.oidc_provider_arn
  oidc_provider_url    = module.eks.oidc_provider_url
  namespace            = "default"
  service_account_name = each.value.sa_name
  service_name         = each.key

  # use the ARN of the secret created above
  db_secret_arn = module.secrets.secret_arn
}

module "external_secrets_role" {
  source            = "../../modules/iam/external_secrets_role"
  env               = var.environment
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  secretsmanager_arns = [
    module.secrets.secret_arn
  ]
}

############################################
# Argo CD Image Updater IAM Role
############################################
module "argocd_image_updater_role" {
  source            = "../../modules/iam/argocd_image_updater_role"
  env               = var.environment
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  ecr_repository_arns = [
    for svc in var.microservices : "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/${svc}"
  ]
}

# GitHub OIDC Module
############################################

module "github_oidc" {
  source              = "../../modules/iam/github_oidc"
  artifacts_s3_bucket = var.artifacts_s3_bucket
  ecr_repository_arns = [
    for svc in var.microservices : "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/${svc}"
  ]
}

############################################
# ALB Controller IAM Role
############################################
module "alb_controller_role" {
  source            = "../../modules/iam/alb_controller_role"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  cluster_name      = var.cluster_name
}

############################################
# Monitoring Infrastructure
############################################
module "monitoring" {
  source = "../../modules/monitoring"

  environment           = var.environment
  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  eks_oidc_provider_url = module.eks.oidc_provider_url
  region                = var.aws_region
  aws_account_id        = var.aws_account_id
}

