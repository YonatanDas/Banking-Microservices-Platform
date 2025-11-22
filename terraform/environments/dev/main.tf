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

  eks_node_sg_id = module.eks.node_sg_id
}

############################################
# ECR Repositories
############################################
module "ecr" {
  source        = "../../modules/ecr"
  service_names = ["accounts", "cards", "loans", "gatewayserver"]
  environment   = var.environment
}

############################################
# IAM Roles
############################################
module "iam_cluster_role" {
  source      = "../../modules/iam/cluster_role"
  name_prefix = "banking"
}

module "iam_node_role" {
  source      = "../../modules/iam/node_role"
  name_prefix = "banking"
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
  db_name     = "${var.environment}_bank"

  db_instance_class = var.db_instance_class
  db_sg_id          = module.vpc.rds_sg_id

  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
}


############################################
# Secrets Manager (creates secret)
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
  microservices = {
    accounts = { sa_name = "accounts-sa" }
    cards    = { sa_name = "cards-sa" }
    loans    = { sa_name = "loans-sa" }
  }
}

module "rds_access_role" {
  source               = "../../modules/iam/rds_access_role"
  for_each             = local.microservices
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

# GitHub OIDC Module
############################################

module "github_oidc" {
  source = "../../modules/iam/github_oidc"
}

############################################
# ALB Controller IAM Role
############################################
module "alb_controller_role" {
  source            = "../../modules/iam/alb_controller_role"
  oidc_provider_arn = module.eks.oidc_provider_arn
}