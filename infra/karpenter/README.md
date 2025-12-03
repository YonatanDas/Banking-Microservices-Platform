# Karpenter Configuration

This directory contains Karpenter configuration manifests for the multi-environment EKS platform.

## Structure

- `provisioners/`: NodePool (Provisioner) configurations per environment
- `ec2nodeclass/`: EC2NodeClass configurations per environment

## Environment-Specific Configurations

### Dev Environment
- **Instance Types**: t3.small, t3.medium, t3.large, m5.large, m5.xlarge
- **Capacity Types**: Spot and On-Demand
- **Consolidation**: WhenEmpty, 30s delay
- **Limits**: 1000 CPU, 2000Gi memory

### Staging Environment
- **Instance Types**: t3.medium, t3.large, t3.xlarge, m5.large, m5.xlarge, m5.2xlarge
- **Capacity Types**: Spot and On-Demand
- **Consolidation**: WhenEmpty, 60s delay
- **Limits**: 2000 CPU, 4000Gi memory

### Production Environment
- **Instance Types**: t3.large, t3.xlarge, m5.large, m5.xlarge, m5.2xlarge, m5.4xlarge
- **Capacity Types**: On-Demand only (for stability)
- **Consolidation**: WhenUnderutilized, 300s delay
- **Limits**: 5000 CPU, 10000Gi memory

## Deployment

These manifests are deployed via ArgoCD. See `gitops/{env}/applications/karpenter-config-{env}.yaml` for ArgoCD application definitions.

## Notes

- All configurations use AL2 (Amazon Linux 2) AMI family
- Subnet discovery uses `karpenter.sh/discovery` tag
- Security group discovery uses Kubernetes cluster tags
- Instance profile is managed by Terraform and referenced in EC2NodeClass

