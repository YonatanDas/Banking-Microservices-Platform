##########################################
# Helm Release: External Secrets Operator
##########################################
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  version          = "0.9.11"

  # Ensure clean uninstall
  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 600
  wait_for_jobs   = false

  set {
    name  = "installCRDs"
    value = "true"
  }


  depends_on = [
    aws_eks_cluster.this,
    aws_iam_openid_connect_provider.eks
  ]
}
