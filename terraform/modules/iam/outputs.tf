output "eks_cluster_role_arn" {
  value = module.cluster_role.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  value = module.node_role.eks_node_role_arn
}

