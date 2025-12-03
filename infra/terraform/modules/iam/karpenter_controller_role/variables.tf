variable "env" {
  description = "Environment name (dev, stag, prod)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC provider (without https://)"
  type        = string
}

variable "node_instance_profile_arn" {
  description = "ARN of the IAM instance profile for Karpenter nodes"
  type        = string
}

