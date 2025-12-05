output "ecr_repository_urls" {
  description = "All created ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "eks_cluster_role_arn" {
  value = module.iam_cluster_role.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  value = module.iam_node_role.eks_node_role_arn
}

output "cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "rds_access_role_arns" {
  description = "IAM role ARNs for all microservices (accounts, cards, loans)"
  value       = { for k, m in module.rds_access_role : k => m.rds_access_role_arn }
}

output "cluster_security_group_id" {
  description = "EKS Cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster"
  value       = module.eks.oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN for the EKS cluster"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "OIDC issuer hostname without https://"
  value       = module.eks.oidc_provider_url
}

output "external_secrets_role_arn" {
  description = "IAM Role ARN for External Secrets Operator"
  value       = module.external_secrets_role.eso_role_arn
}

output "eso_role_arn" {
  description = "IAM Role ARN for External Secrets Operator"
  value       = module.external_secrets_role.eso_role_arn
}

output "loki_s3_bucket_name" {
  description = "S3 bucket name for Loki storage"
  value       = module.monitoring.loki_s3_bucket_name
}

output "loki_iam_role_arn" {
  description = "IAM role ARN for Loki S3 access"
  value       = module.monitoring.loki_iam_role_arn
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = module.eks.grafana_admin_password
  sensitive   = true
}

output "eks_admins_group_arn" {
  description = "ARN of eks-admins IAM group"
  value       = module.eks_users.eks_admins_group_arn
}

output "eks_developers_group_arn" {
  description = "ARN of eks-developers IAM group"
  value       = module.eks_users.eks_developers_group_arn
}

output "eks_viewers_group_arn" {
  description = "ARN of eks-viewers IAM group"
  value       = module.eks_users.eks_viewers_group_arn
}

output "eks_operators_group_arn" {
  description = "ARN of eks-operators IAM group"
  value       = module.eks_users.eks_operators_group_arn
}

output "eks_user_arns" {
  description = "Map of created IAM user ARNs (if users are created)"
  value       = module.eks_users.user_arns
}