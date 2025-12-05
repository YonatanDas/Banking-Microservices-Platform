############################################
# IAM Groups for EKS Access
############################################

resource "aws_iam_group" "eks_admins" {
  name = "eks-admins"
  path = var.group_path
}

resource "aws_iam_group" "eks_developers" {
  name = "eks-developers"
  path = var.group_path
}

resource "aws_iam_group" "eks_viewers" {
  name = "eks-viewers"
  path = var.group_path
}

resource "aws_iam_group" "eks_operators" {
  name = "eks-operators"
  path = var.group_path
}

############################################
# IAM Policy for EKS Cluster Access
############################################

resource "aws_iam_policy" "eks_cluster_access" {
  name        = "${var.name_prefix != "" ? "${var.name_prefix}-" : ""}eks-cluster-access-${var.environment}"
  description = "Policy to allow EKS cluster access"
  path        = var.group_path

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = var.eks_cluster_arn
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy  = "terraform"
  }
}

############################################
# Attach Policy to Groups
############################################

resource "aws_iam_group_policy_attachment" "eks_admins_access" {
  group      = aws_iam_group.eks_admins.name
  policy_arn = aws_iam_policy.eks_cluster_access.arn
}

resource "aws_iam_group_policy_attachment" "eks_developers_access" {
  group      = aws_iam_group.eks_developers.name
  policy_arn = aws_iam_policy.eks_cluster_access.arn
}

resource "aws_iam_group_policy_attachment" "eks_viewers_access" {
  group      = aws_iam_group.eks_viewers.name
  policy_arn = aws_iam_policy.eks_cluster_access.arn
}

resource "aws_iam_group_policy_attachment" "eks_operators_access" {
  group      = aws_iam_group.eks_operators.name
  policy_arn = aws_iam_policy.eks_cluster_access.arn
}


