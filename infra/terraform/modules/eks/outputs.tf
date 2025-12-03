##########################################
# EKS Cluster Outputs
##########################################

output "cluster_name" {
  description = "EKS Cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS Cluster CA certificate"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "EKS Cluster security group ID"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster"
  value       = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN for the EKS cluster"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "OIDC issuer hostname without https://"
  value       = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}

output "node_sg_id" {
  description = "Security Group ID of worker nodes"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "prometheus_service_endpoint" {
  description = "Prometheus service endpoint"
  value       = "kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090"
}

output "grafana_service_endpoint" {
  description = "Grafana service endpoint"
  value       = "kube-prometheus-stack-grafana.monitoring.svc.cluster.local:80"
}

output "karpenter_controller_role_arn" {
  description = "IAM Role ARN for Karpenter Controller"
  value       = var.karpenter_controller_role_arn
}

output "karpenter_node_instance_profile_name" {
  description = "Name of the IAM instance profile for Karpenter nodes"
  value       = var.karpenter_node_instance_profile_name
}