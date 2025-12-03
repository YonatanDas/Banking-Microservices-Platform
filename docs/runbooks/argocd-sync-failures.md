# Runbook: Argo CD Sync Failures

## Overview
This runbook helps diagnose and resolve Argo CD application sync failures.

## Prerequisites
- `kubectl` configured with cluster access
- `argocd` CLI installed (optional)
- Access to Argo CD UI or CLI

## Initial Diagnosis

### 1. Check Application Status
```bash
# List all Argo CD applications
kubectl get application -n argocd

# Get detailed application status
kubectl get application <app-name> -n argocd -o yaml

# Describe application
kubectl describe application <app-name> -n argocd
```

### 2. Check Sync Status via CLI (if available)
```bash
# Login to Argo CD
argocd login <argocd-server> --username admin

# Get application status
argocd app get <app-name>

# View sync history
argocd app history <app-name>
```

## Common Issues and Solutions

### Issue 1: Git Repository Access

**Symptoms:**
- Application status: `Unknown` or `Degraded`
- Error: "repository not accessible"

**Diagnosis:**
```bash
kubectl describe application <app-name> -n argocd | grep -A 10 Conditions
```

**Solutions:**
1. Verify repository URL in Application manifest:
   ```bash
   kubectl get application <app-name> -n argocd -o jsonpath='{.spec.source.repoURL}'
   ```
2. Check repository credentials (if using private repo)
3. Verify network connectivity from Argo CD to Git

### Issue 2: Helm Chart Errors

**Symptoms:**
- Application status: `Degraded`
- Error: "failed to render chart"

**Diagnosis:**
```bash
# Check application conditions
kubectl get application <app-name> -n argocd -o jsonpath='{.status.conditions}' | jq
```

**Solutions:**
1. Run `helm lint` locally on the chart
2. Check Helm values files for syntax errors
3. Verify chart dependencies:
   ```bash
   helm dependency list helm/environments/dev-env
   ```

### Issue 3: Resource Conflicts

**Symptoms:**
- Application status: `Degraded`
- Error: "resource already exists" or "conflict"

**Diagnosis:**
```bash
# Check for conflicting resources
kubectl get all -n default | grep <resource-name>
```

**Solutions:**
1. Check `ignoreDifferences` in Application manifest
2. Manually resolve conflicts:
   ```bash
   kubectl delete <resource-type> <resource-name> -n <namespace>
   ```
3. Re-sync application:
   ```bash
   argocd app sync <app-name>
   ```

### Issue 4: Kyverno Policy Violations

**Symptoms:**
- Application status: `Degraded`
- Resources not created
- Kyverno events in namespace

**Diagnosis:**
```bash
# Check Kyverno events
kubectl get events -n default | grep kyverno

# Check policy violations
kubectl get clusterpolicies
kubectl describe clusterpolicy <policy-name>
```

**Solutions:**
1. Review Kyverno policy requirements
2. Update Helm templates to comply with policies
3. Temporarily disable policy for testing (not recommended for prod)

### Issue 5: Resource Quota Exceeded

**Symptoms:**
- Application status: `Degraded`
- Pods in `Pending` state
- Events show quota exceeded

**Diagnosis:**
```bash
# Check resource quotas
kubectl get resourcequota -n default

# Check limit ranges
kubectl get limitrange -n default
```

**Solutions:**
1. Increase resource quotas in Helm values
2. Scale down other services
3. Request namespace quota increase

## Manual Sync Operations

### Force Sync
```bash
# Via CLI
argocd app sync <app-name> --force

# Via kubectl (patch)
kubectl patch application <app-name> -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

### Hard Refresh
```bash
# Refresh application
argocd app get <app-name> --refresh

# Or via kubectl
kubectl patch application <app-name> -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### Rollback
```bash
# List sync history
argocd app history <app-name>

# Rollback to previous revision
argocd app rollback <app-name> <revision-hash>
```

## Verification

### Check Sync Status
```bash
# Application health
kubectl get application <app-name> -n argocd -o jsonpath='{.status.health.status}'

# Sync status
kubectl get application <app-name> -n argocd -o jsonpath='{.status.sync.status}'

# Resources status
kubectl get application <app-name> -n argocd -o jsonpath='{.status.resources}'
```

### Verify Deployed Resources
```bash
# Check if resources are created
kubectl get all -n default -l app.kubernetes.io/name=<chart-name>

# Verify pod status
kubectl get pods -n default
```

## Prevention

- Enable automated sync with `selfHeal: true`
- Use `prune: true` to clean up deleted resources
- Configure proper `ignoreDifferences` for HPA, Secrets, etc.
- Test Helm charts locally before committing
- Monitor Argo CD applications via Prometheus alerts
- Use sync windows for production (prevent deployments during business hours)

## Escalation

If issues persist:
1. Check Argo CD server logs:
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=100
   ```
2. Review recent Git commits
3. Check Prometheus alerts for Argo CD
4. Contact platform team with:
   - Application name
   - Sync history
   - Relevant error messages
   - Recent changes

