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
          "token.actions.githubusercontent.com:sub" : "repo:YonatanDas/Multi-env-Banking-App:*"
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

      # Push & Pull from ECR
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      },

      # EKS access (depending on your security level)
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "*"
      },

      # kubectl access (via auth token)
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "github_actions_attach" {
  name       = "attach-github-actions-policy"
  roles      = [aws_iam_role.github_actions.name]
  policy_arn = aws_iam_policy.github_actions_policy.arn
}