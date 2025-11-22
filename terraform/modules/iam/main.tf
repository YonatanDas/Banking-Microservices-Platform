##########################################
# IAM Root Module - orchestrates submodules
##########################################

module "cluster_role" {
  source      = "./cluster_role"
  name_prefix = "${var.environment}-${var.cluster_name}"
}

module "node_role" {
  source      = "./node_role"
  name_prefix = "${var.environment}-${var.cluster_name}"
}

module "iam_rds_access_role" {
  source               = "./modules/iam/rds_access_role"
  oidc_provider_url    = module.eks.oidc_issuer_url
  cluster_name         = module.eks.cluster_name
  secretsmanager_arn   = module.secrets.db_secret_arn
  namespace            = "default"
  service_account_name = "rds-access"
}

module "external_secrets_role" {
  source            = "../../modules/iam/external_secrets_role"
  env               = var.environment
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  secretsmanager_arns = [
    "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:dev-db-credentials-*"
  ]
}

module "github_oidc" {
  source = "./github_oidc"
}

module "alb_controller_role" {
  source = "./alb_controller_role"
}