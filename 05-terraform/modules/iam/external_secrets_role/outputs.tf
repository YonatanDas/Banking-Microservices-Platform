##########################################
# IAM Role Output for External Secrets Operator
##########################################
output "eso_role_arn" {
  description = "IAM Role ARN for External Secrets Operator"
  value       = aws_iam_role.eso_role.arn
}
