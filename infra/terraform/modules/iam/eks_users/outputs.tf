output "eks_admins_group_arn" {
  description = "ARN of the eks-admins IAM group (for aws-auth ConfigMap)"
  value       = aws_iam_group.eks_admins.arn
}

output "eks_developers_group_arn" {
  description = "ARN of the eks-developers IAM group (for aws-auth ConfigMap)"
  value       = aws_iam_group.eks_developers.arn
}

output "eks_viewers_group_arn" {
  description = "ARN of the eks-viewers IAM group (for aws-auth ConfigMap)"
  value       = aws_iam_group.eks_viewers.arn
}

output "eks_operators_group_arn" {
  description = "ARN of the eks-operators IAM group (for aws-auth ConfigMap)"
  value       = aws_iam_group.eks_operators.arn
}

output "eks_cluster_access_policy_arn" {
  description = "ARN of the EKS access policy"
  value       = aws_iam_policy.eks_cluster_access.arn
}



