###############################################
# GitHub OIDC Terraform Role
###############################################
resource "aws_iam_role" "github_actions_terraform" {
  name = "github-actions-terraform-role"

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
          # Allow ONLY your repo Terraform workflows to assume the role
          "token.actions.githubusercontent.com:sub" : "repo:YonatanDas/Multi-env-Banking-App:ref:refs/heads/*"
        }
      }
    }]
  })
}

###############################################
# IAM Policy for Terraform Plan + Apply
###############################################
resource "aws_iam_policy" "github_actions_terraform_policy" {
  name        = "github-actions-terraform-policy"
  description = "Permissions required for GitHub Actions to run Terraform plan/apply for EKS, VPC, RDS, IAM, and supporting resources."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      ############################################################
      # S3 (Terraform backend + artifact upload)
      ############################################################
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:PutObjectAcl"
        ],
        Resource = [
          "arn:aws:s3:::my-ci-artifacts55",
          "arn:aws:s3:::my-ci-artifacts55/*"
        ]
      },

      ############################################################
      # ECR (repos + lifecycle rules)
      ############################################################
      {
        Effect = "Allow",
        Action = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:DescribeRepositories",
          "ecr:PutLifecyclePolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      },

      ############################################################
      # VPC / Subnets / NAT / IGW / Routes
      ############################################################
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:CreateRoute",
          "ec2:CreateRouteTable",
          "ec2:AssociateRouteTable",
          "ec2:CreateInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:CreateNatGateway",
          "ec2:AllocateAddress",
          "ec2:Describe*"
        ],
        Resource = "*"
      },

      ############################################################
      # Security Groups
      ############################################################
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DescribeSecurityGroups"
        ],
        Resource = "*"
      },

      ############################################################
      # IAM (EKS roles, node roles, IRSA, GitHub OIDC)
      ############################################################
      {
        Effect = "Allow",
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRole",
          "iam:PassRole",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider"
        ],
        Resource = "*"
      },

      ############################################################
      # EKS Cluster & Node Groups
      ############################################################
      {
        Effect = "Allow",
        Action = [
          "eks:CreateCluster",
          "eks:DescribeCluster",
          "eks:DeleteCluster",
          "eks:CreateNodegroup",
          "eks:DescribeNodegroup",
          "eks:DeleteNodegroup"
        ],
        Resource = "*"
      },

      ############################################################
      # RDS (instance + subnet group)
      ############################################################
      {
        Effect = "Allow",
        Action = [
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:ModifyDBInstance",
          "rds:DescribeDBInstances",
          "rds:CreateDBSubnetGroup",
          "rds:DeleteDBSubnetGroup",
          "rds:DescribeDBSubnetGroups"
        ],
        Resource = "*"
      },

      ############################################################
      # Secrets Manager (DB credentials)
      ############################################################
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:DeleteSecret"
        ],
        Resource = "*"
      },

      ############################################################
      # KMS (optional depending on your encryption)
      ############################################################
      {
        Effect = "Allow",
        Action = [
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:EnableKeyRotation",
          "kms:CreateAlias"
        ],
        Resource = "*"
      }
    ]
  })
}

###############################################
# Attach policy to role
###############################################
resource "aws_iam_policy_attachment" "github_actions_terraform_attach" {
  name       = "attach-github-actions-terraform-policy"
  roles      = [aws_iam_role.github_actions_terraform.name]
  policy_arn = aws_iam_policy.github_actions_terraform_policy.arn
}