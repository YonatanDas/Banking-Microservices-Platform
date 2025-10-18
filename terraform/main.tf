module "vpc" {
  source              = "./modules/vpc"
  env                 = var.env
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
}

module "ecr" {
  source        = "./modules/ecr"
  service_names = ["accounts", "cards", "loans", "configserver", "gateway"]
  environment   = var.env
}

