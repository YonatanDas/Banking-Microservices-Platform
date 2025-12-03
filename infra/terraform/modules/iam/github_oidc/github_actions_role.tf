resource "aws_iam_role" "github_actions" {
  name = "github-actions-eks-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_oidc.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" : "repo:YonatanDas/Banking-Microservices-Platform:*"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "github_actions_policy" {
  name        = "github-actions-eks-ecr-policy"
  description = "Allow GitHub Actions to push to ECR and deploy to EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # ECR Authorization (required for all ECR operations)
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      # Push & Pull from specific ECR repositories
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:DescribeRepositories"
        ]
        Resource = length(var.ecr_repository_arns) > 0 ? var.ecr_repository_arns : ["*"]
      },

      # S3 access for artifact storage
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ]
        "Resource" : [
          "arn:aws:s3:::${var.artifacts_s3_bucket}",
          "arn:aws:s3:::${var.artifacts_s3_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "github_actions_attach" {
  name       = "attach-github-actions-policy"
  roles      = [aws_iam_role.github_actions.name]
  policy_arn = aws_iam_policy.github_actions_policy.arn
}