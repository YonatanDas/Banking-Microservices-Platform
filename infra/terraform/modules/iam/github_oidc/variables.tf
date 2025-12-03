variable "artifacts_s3_bucket" {
  description = "S3 bucket name for CI/CD artifacts storage"
  type        = string
  default     = "my-ci-artifacts55"
}

variable "ecr_repository_arns" {
  description = "ARNs of ECR repositories GitHub Actions can push/pull from"
  type        = list(string)
  default     = []
}

