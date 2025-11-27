variable "service_names" {
  description = "List of microservice ECR repositories to create"
  type        = list(string)
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}
