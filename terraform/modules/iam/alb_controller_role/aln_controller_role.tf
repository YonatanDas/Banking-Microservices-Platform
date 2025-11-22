##############################################
# IAM ROLE FOR AWS LOAD BALANCER CONTROLLER
##############################################
resource "aws_iam_role" "alb_controller" {
  name = "aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = var.oidc_provider_arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${var.oidc_provider_arn}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}
##############################################
# IAM POLICY FOR ALB CONTROLLER
##############################################

resource "aws_iam_policy" "alb_controller_policy" {
  name        = "aws-load-balancer-controller-policy"
  description = "Permissions for AWS Load Balancer Controller to manage ALBs and Target Groups"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # Required by AWS documentation for ALB Controller
      {
        Effect = "Allow",
        Action = [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "elasticloadbalancing:*"
        ],
        Resource = "*"
      },

      {
        Effect = "Allow",
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL"
        ],
        Resource = "*"
      }
    ]
  })
}

##############################################
# ATTACH IAM POLICY TO ROLE
##############################################

resource "aws_iam_policy_attachment" "alb_controller_attach" {
  name       = "attach-alb-controller-policy"
  roles      = [aws_iam_role.alb_controller.name]
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}