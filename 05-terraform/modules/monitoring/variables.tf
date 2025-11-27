variable "environment" {
  description = "Environment name (dev, stag, prod)"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "EKS OIDC Provider ARN for IRSA"
  type        = string
}

variable "eks_oidc_provider_url" {
  description = "EKS OIDC Provider URL"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

