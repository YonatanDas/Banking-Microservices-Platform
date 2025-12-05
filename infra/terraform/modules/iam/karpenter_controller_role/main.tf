##########################################
# IAM Role for Karpenter Controller (IRSA)
##########################################
locals {
  oidc_sub = "system:serviceaccount:karpenter:karpenter"
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

resource "aws_iam_role" "karpenter_controller" {
  name               = "${var.env}-karpenter-controller-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  description        = "IRSA role for Karpenter Controller"
}

##########################################
# IAM Policy for Karpenter Controller
##########################################
data "aws_iam_policy_document" "karpenter_controller_policy" {
  # EC2 Instance Management
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DeleteLaunchTemplate", 
      "ec2:CreateFleet",
      "ec2:CreateTags",
      "ec2:RunInstances",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeImages",
      "ec2:TerminateInstances",
      "ec2:DescribeSpotPriceHistory"
    ]
    resources = ["*"]
  }

  # Networking
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeAvailabilityZones"
    ]
    resources = ["*"]
  }

  # SSM Parameter Store (for AMI lookup)
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/aws/service/eks/optimized-ami/*"
    ]
  }

  # IAM PassRole (for node instance profile)
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      var.node_instance_profile_arn
    ]
  }

  # Pricing (optional, for spot pricing)
  statement {
    effect = "Allow"
    actions = [
      "pricing:GetProducts"
    ]
    resources = ["*"]
  }

  # EKS Cluster Access (required for Karpenter to discover cluster)
  statement {
    effect = "Allow"
    actions = [
      "eks:DescribeCluster"
    ]
    resources = [
      var.eks_cluster_arn
    ]
  }
  # IAM PassRole (for node instance profile and role)
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      var.node_instance_profile_arn,
      var.node_role_arn
    ]
  }
  # Tagging
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags"
    ]
    resources = [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:launch-template/*",
      "arn:aws:ec2:*:*:fleet/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "RunInstances",
        "CreateLaunchTemplate",
        "CreateFleet"
      ]
    }
  }
}

resource "aws_iam_policy" "karpenter_controller_policy" {
  name        = "${var.env}-karpenter-controller-policy"
  description = "Permissions for Karpenter Controller to manage EC2 instances"
  policy      = data.aws_iam_policy_document.karpenter_controller_policy.json
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
}

