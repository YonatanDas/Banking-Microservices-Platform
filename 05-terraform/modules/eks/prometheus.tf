##########################################
# Monitoring Namespace
##########################################
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
  timeouts {
    delete = "5m"
  }
}

# Prometheus Operator is now managed by ArgoCD via GitOps
# Removed helm_release.prometheus_operator to avoid conflicts

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = "admin123"
  sensitive   = true
}