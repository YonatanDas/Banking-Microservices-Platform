output "rds_access_role_arn" {
  description = "IAM role ARN for RDS access via IRSA"
  value       = aws_iam_role.rds_access_role.arn
}

