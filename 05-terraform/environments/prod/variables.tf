variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources into"
  default     = "us-east-1"
}

variable "environment" {
  default = "dev"
}

variable "name_prefix" {
  type    = string
  default = "banking"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
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
  validation {
    condition     = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", var.node_instance_type))
    error_message = "Instance type must be in format 'family.size' (e.g., t3.medium, m5.large)."
  }
}

variable "node_desired_capacity" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
  validation {
    condition     = var.node_desired_capacity >= 1
    error_message = "Desired capacity must be at least 1."
  }
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
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS Account ID must be exactly 12 digits."
  }
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "dbadmin"
}
variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "prod_bank"
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
}

variable "deletion_protection" {
  description = "Enable deletion protection for the RDS instance"
  type        = bool
}

variable "artifacts_s3_bucket" {
  description = "S3 bucket name for CI/CD artifacts storage"
  type        = string
  default     = "my-ci-artifacts55"
}