##########################################
# General Variables
##########################################
variable "cluster_name" {
  type        = string
}

variable "cluster_version" {
  type        = string
  default     = "1.30"
}

variable "environment" {
  type        = string
  default     = "prod"
}

##########################################
# Networking Variables
##########################################
variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

##########################################
# IAM Role Variables
##########################################
variable "cluster_role_arn" {
  description = "IAM role ARN for the control plane"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for the worker nodes"
  type        = string
}

##########################################
# Node Group Variables
##########################################
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
