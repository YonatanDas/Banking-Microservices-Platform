resource "aws_iam_role" "loki_s3_access" {
  name = "${var.environment}-loki-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.eks_oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.eks_oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:monitoring:loki"
          "${replace(var.eks_oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Environment = var.environment
    Purpose     = "LokiS3Access"
  }
}

resource "aws_iam_role_policy" "loki_s3_policy" {
  name = "${var.environment}-loki-s3-policy"
  role = aws_iam_role.loki_s3_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ]
      Resource = [
        aws_s3_bucket.loki_storage.arn,
        "${aws_s3_bucket.loki_storage.arn}/*"
      ]
    }]
  })
}

