##########################################
# Helm Release: Argo CD
##########################################
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }

  timeouts {
    delete = "5m"
  }
}


resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.0"

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }


  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.default,
    helm_release.aws_load_balancer_controller
  ]

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 600
  wait_for_jobs   = false
}
