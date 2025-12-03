##########################################
#  Secrets Manager - DB Credentials
##########################################
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = var.secret_name
  description             = "Database credentials for ${var.environment} environment"
  recovery_window_in_days = 7

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "banking-app"
  }
}

##########################################
# Secrets Manager Secret Version - The secret values
##########################################
resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbhost   = var.db_endpoint
    dbname   = var.db_name
  })
}

