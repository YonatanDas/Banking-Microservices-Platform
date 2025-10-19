module "vpc" {
  source              = "./modules/vpc"
  env                 = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
}

module "ecr" {
  source        = "./modules/ecr"
  service_names = ["accounts", "cards", "loans", "configserver", "gateway"]
  environment   = var.environment
}

module "iam_cluster_role" {
  source      = "./modules/iam/cluster_role"
  name_prefix = "banking"
}

module "iam_node_role" {
  source      = "./modules/iam/node_role"
  name_prefix = "banking"
}

module "eks" {
  source = "./modules/eks"

  # identifiers
  cluster_name = var.cluster_name
  environment  = "prod"

  # networking
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets

  # IAM
  cluster_role_arn = module.iam_cluster_role.eks_cluster_role_arn
  node_role_arn    = module.iam_node_role.eks_node_role_arn

  # node group settings
  node_instance_type    = "t3.medium"
  node_desired_capacity = 2
}
