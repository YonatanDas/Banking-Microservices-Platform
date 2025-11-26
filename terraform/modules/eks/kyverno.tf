##########################################
# Helm Release: Kyverno
##########################################
resource "helm_release" "kyverno" {
  name       = "kyverno"
  namespace  = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  version    = "3.1.0"

  create_namespace = true

  set {
    name  = "replicaCount"
    value = "3"
  }

  set {
    name  = "initContainer.image.registry"
    value = "ghcr.io"
  }

  set {
    name  = "initContainer.image.repository"
    value = "kyverno/kyvernopre"
  }

  set {
    name  = "initContainer.image.tag"
    value = "v1.12.0"
  }

  set {
    name  = "metricsService.enabled"
    value = "true"
  }

  set {
    name  = "backgroundController.enabled"
    value = "true"
  }

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "resources.limits.cpu"
    value = "1000m"
  }

  set {
    name  = "resources.limits.memory"
    value = "1Gi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "200m"
  }

  set {
    name  = "resources.requests.memory"
    value = "256Mi"
  }

  set {
    name  = "cleanupController.enabled"
    value = "true"
  }

  set {
    name  = "cleanupController.admissionReports.enabled"
    value = "true"
  }

  set {
    name  = "cleanupController.clusterAdmissionReports.enabled"
    value = "true"
  }

  # Increase webhook timeout to prevent ServiceMonitor creation timeouts
  set {
    name  = "admissionController.timeoutSeconds"
    value = "30"
  }

  set {
    name  = "admissionController.failurePolicy"
    value = "Ignore" # This allows deployments even if Kyverno is slow
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.default,
    helm_release.argocd
  ]

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 600
  wait_for_jobs   = false
}