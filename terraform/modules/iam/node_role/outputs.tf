output "eks_node_role_arn" {
  description = "ARN of the EKS Node IAM Role"
  value       = aws_iam_role.eks_node_role.arn
}
