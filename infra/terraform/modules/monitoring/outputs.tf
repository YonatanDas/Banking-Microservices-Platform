output "loki_s3_bucket_name" {
  description = "S3 bucket name for Loki storage"
  value       = aws_s3_bucket.loki_storage.id
}

output "loki_iam_role_arn" {
  description = "IAM role ARN for Loki S3 access"
  value       = aws_iam_role.loki_s3_access.arn
}

