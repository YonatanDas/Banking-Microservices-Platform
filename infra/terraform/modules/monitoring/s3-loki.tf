resource "aws_s3_bucket" "loki_storage" {
  bucket = "${var.environment}-loki-storage-${var.aws_account_id}"

  tags = {
    Environment = var.environment
    Purpose     = "LokiObjectStorage"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "loki_storage" {
  bucket = aws_s3_bucket.loki_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}



