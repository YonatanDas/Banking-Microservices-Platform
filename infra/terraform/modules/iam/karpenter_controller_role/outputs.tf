##########################################
# IAM Role Output for Karpenter Controller
##########################################
output "karpenter_controller_role_arn" {
  description = "IAM Role ARN for Karpenter Controller"
  value       = aws_iam_role.karpenter_controller.arn
}

