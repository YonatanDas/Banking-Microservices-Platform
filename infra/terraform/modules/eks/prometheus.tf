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

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = "external-secrets"  # Matches the value in dev.yaml
  sensitive   = true
}