variable "env" {
  type        = string
  description = "Environment name (dev, stag, prod)"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider"
}

variable "oidc_provider_url" {
  type        = string
  description = "OIDC provider URL (without https://)"
}

variable "ecr_repository_arns" {
  type        = list(string)
  description = "ARNs of ECR repositories Image Updater can read"
  default     = ["*"] # Allow all repositories, or specify specific ones
}