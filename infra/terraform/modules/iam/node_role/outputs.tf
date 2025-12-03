output "eks_node_role_arn" {
  description = "ARN of the EKS Node IAM Role"
  value       = aws_iam_role.eks_node_role.arn
}

output "karpenter_node_instance_profile_name" {
  description = "Name of the IAM instance profile for Karpenter nodes"
  value       = aws_iam_instance_profile.karpenter_node.name
}

output "karpenter_node_instance_profile_arn" {
  description = "ARN of the IAM instance profile for Karpenter nodes"
  value       = aws_iam_instance_profile.karpenter_node.arn
}