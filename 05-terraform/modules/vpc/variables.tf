variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "eks_node_sg_id" {
  type = string
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name for Kubernetes subnet tags"
}