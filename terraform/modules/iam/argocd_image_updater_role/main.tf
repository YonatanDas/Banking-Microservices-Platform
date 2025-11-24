##########################################
# IAM Role and Policy for Argo CD Image Updater with IRSA
##########################################
locals {
  oidc_sub = "system:serviceaccount:argocd:argocd-image-updater"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = [local.oidc_sub]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "image_updater_role" {
  name               = "${var.env}-argocd-image-updater-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  description        = "IRSA role for Argo CD Image Updater to read ECR images"
}

data "aws_iam_policy_document" "image_updater_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  # Repository-specific actions
  statement {
    effect = "Allow"
    actions = [
      "ecr:DescribeImages",
      "ecr:ListImages",
      "ecr:DescribeRepositories"
    ]
    resources = var.ecr_repository_arns
  }
}

resource "aws_iam_policy" "image_updater_policy" {
  name        = "${var.env}-argocd-image-updater-policy"
  description = "Argo CD Image Updater read access to ECR repositories"
  policy      = data.aws_iam_policy_document.image_updater_policy.json
}

resource "aws_iam_role_policy_attachment" "image_updater_policy_attach" {
  role       = aws_iam_role.image_updater_role.name
  policy_arn = aws_iam_policy.image_updater_policy.arn
}