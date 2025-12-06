############################################
# Outputs for Secrets Manager Module
############################################

# The ARN of the created secret (used by IAM module)
output "secret_arn" {
  description = "The ARN of the RDS credentials secret."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

# The name of the secret (useful for data sources or debugging)
output "secret_name" {
  description = "The name of the RDS credentials secret."
  value       = aws_secretsmanager_secret.db_credentials.name
}

# The ID of the secret (rarely needed, but good for internal use)
output "secret_id" {
  description = "The internal AWS ID of the secret."
  value       = aws_secretsmanager_secret.db_credentials.id
}