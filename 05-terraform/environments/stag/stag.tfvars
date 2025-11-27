# Terraform variables for the Staging environment
############################################
environment    = "stag"
aws_account_id = "063630846340"

# EKS Cluster Name
############################################
cluster_name = "bankingapp-stag-eks"

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
