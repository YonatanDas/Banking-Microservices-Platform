# Runbook: Scaling Services

## Overview
This runbook describes how to scale banking microservices (accounts, cards, loans, gateway) horizontally or vertically.

## Prerequisites
- `kubectl` configured with cluster access
- Appropriate RBAC permissions
- Access to Argo CD (if using GitOps)

## Horizontal Scaling (Recommended)

### Method 1: Update Helm Values (GitOps - Recommended)
1. Edit the environment values file:
   ```bash
   # For dev environment
   vim 06-helm/environments/dev-env/values.yaml
   ```
2. Update `replicaCount` for the service:
   ```yaml
   accounts:
     replicaCount: 5  # Increase from current value
   ```
3. Commit and push changes:
   ```bash
   git add 06-helm/environments/dev-env/values.yaml
   git commit -m "Scale accounts service to 5 replicas"
   git push origin main
   ```
4. Argo CD will automatically sync the changes (or manually sync via UI/CLI)

### Method 2: Direct kubectl (Temporary)
```bash
# Scale a specific service
kubectl scale deployment accounts --replicas=5 -n default

# Verify scaling
kubectl get pods -l app=accounts -n default
```

**Note:** Direct kubectl changes will be reverted by Argo CD if `selfHeal: true` is enabled.

## Vertical Scaling (Resource Limits)

1. Edit Helm values to increase resource limits:
   ```yaml
   accounts:
     resources:
       requests:
         cpu: 500m
         memory: 1Gi
       limits:
         cpu: 2000m
         memory: 4Gi
   ```
2. Commit and push changes (GitOps) or apply directly
3. Pods will be recreated with new resource limits

## Autoscaling (HPA)

HPA is already configured via `06-helm/bankingapp-common/templates/_hpa.tpl`. To adjust:

1. Edit Helm values:
   ```yaml
   accounts:
     autoscaling:
       enabled: true
       minReplicas: 2
       maxReplicas: 10
       targetCPUUtilizationPercentage: 70
       targetMemoryUtilizationPercentage: 80
   ```
2. Commit and push changes

## Verification

```bash
# Check current replica count
kubectl get deployment accounts -n default

# Check HPA status
kubectl get hpa accounts-hpa -n default

# Check pod resource usage
kubectl top pods -l app=accounts -n default
```

## Rollback

If scaling causes issues:

1. Revert Helm values to previous replica count
2. Commit and push (GitOps) or scale down directly:
   ```bash
   kubectl scale deployment accounts --replicas=2 -n default
   ```

## Troubleshooting

- **Pods not starting**: Check resource quotas and limit ranges
- **HPA not working**: Verify metrics-server is running: `kubectl get deployment metrics-server -n kube-system`
- **Slow scaling**: Check HPA sync period and scale-down delay settings

