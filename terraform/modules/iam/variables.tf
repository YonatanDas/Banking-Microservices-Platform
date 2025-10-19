variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}


variable "name_prefix" {
  type        = string
  default     = "banking"
}

