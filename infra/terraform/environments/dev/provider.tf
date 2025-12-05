provider "aws" {
  region = "us-east-1" # Specify your desired AWS region
}

# Kubernetes provider for managing aws-auth ConfigMap
# This requires the EKS cluster to exist and proper AWS credentials
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
}

