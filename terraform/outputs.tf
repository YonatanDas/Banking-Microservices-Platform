output "ecr_repository_urls" {
  description = "All created ECR repository URLs"
  value       = module.ecr.repository_urls
}
