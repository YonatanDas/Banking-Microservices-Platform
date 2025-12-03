##########################################
# Helm Release: Karpenter
##########################################
resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = "karpenter"
  }

  timeouts {
    delete = "5m"
  }
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = kubernetes_namespace.karpenter.metadata[0].name
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "0.37.0"

  # Ensure clean uninstall
  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 600
  wait_for_jobs   = false

  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "settings.defaultInstanceProfile"
    value = var.karpenter_node_instance_profile_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.karpenter_controller_role_arn
  }

  set {
    name  = "replicas"
    value = var.karpenter_replicas
  }

  dynamic "set" {
    for_each = var.karpenter_interruption_queue != "" ? [1] : []
    content {
      name  = "settings.interruptionQueue"
      value = var.karpenter_interruption_queue
    }
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_openid_connect_provider.eks
  ]
}

