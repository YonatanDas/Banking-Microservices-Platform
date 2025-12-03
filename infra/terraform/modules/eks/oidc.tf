##########################################
# Create OIDC provider for IRSA
##########################################
data "tls_certificate" "eks" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint] # standard for EKS OIDC
  url             = data.aws_eks_cluster.this.identity[0].oidc[0].issuer

  depends_on = [
    aws_eks_cluster.this
  ]
}