# Terraform variables for the Production environment
############################################
environment    = "prod"
aws_account_id = "063630846340"

# EKS Cluster Name
############################################
cluster_name = "bankingapp-prod-eks"

# VPC Configuration
############################################
vpc_cidr = "10.0.0.0/16"

# EKS Node Group Configuration
############################################
node_instance_type    = "t3.2xlarge"
node_desired_capacity = 4
node_min_size         = 2
node_max_size         = 6

# RDS Database Configuration
############################################
db_instance_class       = "db.m5.large"
db_username             = "bankingdb"
backup_retention_period = 7
deletion_protection     = true