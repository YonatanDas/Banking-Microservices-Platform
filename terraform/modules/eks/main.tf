##########################################
# EKS Cluster and Node Group Definition
##########################################

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = concat(var.private_subnets, var.public_subnets)
  }

  # Control Plane Logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}

##########################################
# EKS Node Group
##########################################

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnets

  scaling_config {
    desired_size = var.node_desired_capacity
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  instance_types = [var.node_instance_type]
  capacity_type  = "ON_DEMAND"

  tags = {
    Name        = "${var.cluster_name}-node"
    Environment = var.environment
  }

  depends_on = [
    aws_eks_cluster.this
  ]
}

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


##########################################
# Helm Release: AWS ALB Controller
##########################################
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  version    = "1.7.2"

  # Ensure clean uninstall
  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 600
  wait_for_jobs   = false

  set {
    name  = "clusterName"
    value = aws_eks_cluster.this.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.alb_controller_role_arn
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_openid_connect_provider.eks,
    aws_eks_node_group.default
  ]
}


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
    value = "500m"
  }

  set {
    name  = "resources.limits.memory"
    value = "512Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
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