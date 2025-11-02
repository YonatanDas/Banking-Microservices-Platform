# Terraform variables for the Dev environment
############################################
environment = "dev"
aws_account_id = "063630846340"

# EKS Cluster Name
############################################
cluster_name = "bankingapp-dev-eks"

# VPC Configuration
############################################
vpc_cidr = "10.0.0.0/16"

# EKS Node Group Configuration
############################################
node_instance_type = "t3.medium"
node_desired_capacity = 2
node_min_size = 1
node_max_size = 3

# RDS Database Configuration
############################################
db_instance_class = "db.t3.micro"
db_username = "bankingdb"
backup_retention_period = 0
deletion_protection = false

