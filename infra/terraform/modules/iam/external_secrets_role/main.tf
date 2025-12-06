##########################################
# IAM Role and Policy for External Secrets Operator (ESO) with IRSA
##########################################
locals {
  oidc_sub = "system:serviceaccount:external-secrets:external-secrets-sa"
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

resource "aws_iam_role" "eso_role" {
  name               = "${var.env}-external-secrets-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  description        = "IRSA role for External Secrets Operator"
}

data "aws_iam_policy_document" "eso_policy" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets"
    ]
    resources = var.secretsmanager_arns
  }
}

resource "aws_iam_policy" "eso_policy" {
  name        = "${var.env}-external-secrets-policy"
  description = "ESO read access to AWS Secrets Manager"
  policy      = data.aws_iam_policy_document.eso_policy.json
}

resource "aws_iam_role_policy_attachment" "eso_policy_attach" {
  role       = aws_iam_role.eso_role.name
  policy_arn = aws_iam_policy.eso_policy.arn
}
