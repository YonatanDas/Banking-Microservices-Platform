variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources into"
  default     = "us-east-1"
}

variable "environment" {
  default = "dev"
}

variable "name_prefix" {
  type        = string
  default     = "banking"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "banking-app-cluster"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_capacity" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3
}
variable "db_instance_class" {}

variable "aws_account_id" {
  description = "The AWS Account ID where resources will be created"
  type        = string  
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "dbadmin"
}
variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "dev_bank"
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
}

variable "deletion_protection" {
  description = "Enable deletion protection for the RDS instance"
  type        = bool
}



