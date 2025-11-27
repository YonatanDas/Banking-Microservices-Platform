##########################################
# ECR Repository Outputs
##########################################
output "repository_urls" {
  description = "ECR repository URLs for all microservices"
  value       = { for k, repo in aws_ecr_repository.repos : k => repo.repository_url }
}

