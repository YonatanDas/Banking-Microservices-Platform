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

output "cluster_certificate_authority_data" {
  description = "EKS Cluster CA certificate"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_security_group_id" {
  description = "EKS Cluster security group ID"
  value       = module.eks.cluster_security_group_id
}
