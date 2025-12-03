# Terraform variables for the Staging environment
############################################
environment    = "stag"
aws_account_id = "063630846340"

# Platform Configuration
#############################################
name_prefix   = "banking"
project_name  = "Banking-App"
db_name_suffix = "bank"

# EKS Cluster Name
############################################
cluster_name = "bankingapp-stag-eks"

# Microservices Configuration
#############################################
microservices = ["accounts", "cards", "loans", "gatewayserver"]

service_registry = {
  accounts = {
    service_account_name = "accounts-sa"
    port                 = 8080
    needs_rds_access     = true
    helm_name            = "accounts"
  }
  cards = {
    service_account_name = "cards-sa"
    port                 = 9000
    needs_rds_access     = true
    helm_name            = "cards"
  }
  loans = {
    service_account_name = "loans-sa"
    port                 = 8090
    needs_rds_access     = true
    helm_name            = "loans"
  }
  gatewayserver = {
    service_account_name = "gateway-sa"
    port                 = 8072
    needs_rds_access     = false
    helm_name            = "gateway"
  }
}

# VPC Configuration
############################################
vpc_cidr = "10.0.0.0/16"

# EKS Node Group Configuration
############################################
node_instance_type    = "t3.large"
node_desired_capacity = 3
node_min_size         = 2
node_max_size         = 4

# RDS Database Configuration
############################################
db_instance_class       = "db.m5.medium"
db_username             = "bankingdb"
backup_retention_period = 7
deletion_protection     = true
