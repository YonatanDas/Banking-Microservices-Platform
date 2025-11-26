# Runbook: Troubleshooting Pod Crashes

## Overview
This runbook helps diagnose and resolve pod crash loop issues in the banking microservices platform.

## Prerequisites
- `kubectl` configured with cluster access
- Access to logs and events

## Initial Diagnosis

### 1. Identify Crashing Pods
```bash
# List pods with status issues
kubectl get pods -n default | grep -E "CrashLoopBackOff|Error|Pending"

# Get detailed pod status
kubectl describe pod <pod-name> -n default
```

### 2. Check Pod Events
```bash
# View recent events
kubectl get events -n default --sort-by='.lastTimestamp' | tail -20

# Filter events for specific pod
kubectl describe pod <pod-name> -n default | grep -A 10 Events
```

### 3. Check Pod Logs
```bash
# Current logs
kubectl logs <pod-name> -n default

# Previous container logs (if pod restarted)
kubectl logs <pod-name> -n default --previous

# Follow logs in real-time
kubectl logs -f <pod-name> -n default
```

## Common Issues and Solutions

### Issue 1: Application Startup Failure

**Symptoms:**
- Pod starts but exits immediately
- Logs show application errors

**Diagnosis:**
```bash
kubectl logs <pod-name> -n default --previous
```

**Common Causes:**
- Database connection failure
- Missing environment variables
- Invalid configuration

**Solutions:**
1. Check ExternalSecret status:
   ```bash
   kubectl get externalsecret -n default
   kubectl describe externalsecret <secret-name> -n default
   ```
2. Verify ConfigMap:
   ```bash
   kubectl get configmap bankingapp-config -n default -o yaml
   ```
3. Check database connectivity (if RDS):
   ```bash
   kubectl exec -it <pod-name> -n default -- env | grep DB
   ```

### Issue 2: Resource Constraints

**Symptoms:**
- Pod status: `Pending` or `OOMKilled`
- Events show resource quota exceeded

**Diagnosis:**
```bash
# Check resource quotas
kubectl get resourcequota -n default

# Check limit ranges
kubectl get limitrange -n default

# Check node resources
kubectl top nodes
```

**Solutions:**
1. Increase resource limits in Helm values
2. Request quota increase (if needed)
3. Scale down other services temporarily

### Issue 3: Image Pull Errors

**Symptoms:**
- Pod status: `ImagePullBackOff` or `ErrImagePull`
- Events show authentication errors

**Diagnosis:**
```bash
kubectl describe pod <pod-name> -n default | grep -A 5 Events
```

**Solutions:**
1. Verify image exists in ECR:
   ```bash
   aws ecr describe-images --repository-name accounts --region us-east-1
   ```
2. Check image pull secrets:
   ```bash
   kubectl get secrets -n default | grep ecr
   ```
3. Verify ECR permissions for node role

### Issue 4: Network Policy Blocking

**Symptoms:**
- Pod starts but can't communicate
- Connection timeouts in logs

**Diagnosis:**
```bash
# Check NetworkPolicies
kubectl get networkpolicy -n default

# Describe specific policy
kubectl describe networkpolicy <policy-name> -n default
```

**Solutions:**
1. Review NetworkPolicy rules
2. Add required ingress/egress rules
3. Temporarily disable policy for testing (not recommended for prod)

### Issue 5: Security Context Violations

**Symptoms:**
- Pod fails with permission denied errors
- Kyverno policy violations

**Diagnosis:**
```bash
# Check Kyverno policy violations
kubectl get events -n default | grep kyverno

# Check pod security context
kubectl get pod <pod-name> -n default -o yaml | grep -A 10 securityContext
```

**Solutions:**
1. Verify securityContext in Helm templates
2. Check Kyverno policies:
   ```bash
   kubectl get clusterpolicies
   kubectl describe clusterpolicy require-non-root
   ```

## Advanced Debugging

### Exec into Pod
```bash
# If pod is running
kubectl exec -it <pod-name> -n default -- /bin/sh

# Check environment variables
kubectl exec <pod-name> -n default -- env

# Test database connectivity
kubectl exec <pod-name> -n default -- nc -zv <db-host> 5432
```

### Check Service Account and IRSA
```bash
# Verify ServiceAccount
kubectl get serviceaccount <sa-name> -n default -o yaml

# Check IRSA annotation
kubectl get serviceaccount accounts-sa -n default -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'
```

## Escalation

If issues persist:
1. Check Prometheus alerts for related metrics
2. Review Grafana dashboards for service health
3. Check Argo CD sync status
4. Review recent deployments/changes
5. Contact platform team with:
   - Pod name and namespace
   - Relevant logs
   - Events output
   - Recent changes

## Prevention

- Enable health checks (liveness/readiness probes)
- Set appropriate resource limits
- Use PodDisruptionBudgets for high availability
- Monitor with Prometheus alerts
- Test changes in dev/staging first

