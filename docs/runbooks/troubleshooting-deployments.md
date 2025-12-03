# Troubleshooting Deployments

Common deployment issues and their solutions.

## Pre-Deployment Issues

### Image Signature Validation Fails

**Symptoms**: 
- Workflow fails at "Validate image signature" step
- Error: "Image signature verification failed"

**Solutions**:
1. Check if image was signed during CI/CD build
2. Verify Cosign signing step completed in build workflow
3. Re-sign the image if needed:
   ```bash
   export COSIGN_EXPERIMENTAL=1
   cosign sign ${REGISTRY}/${SERVICE}:${TAG}
   ```

### Image Doesn't Exist in ECR

**Symptoms**:
- Workflow fails at "Verify image exists in ECR" step
- Error: "Image does not exist in ECR"

**Solutions**:
1. Verify image was built and pushed successfully
2. Check ECR repository:
   ```bash
   aws ecr describe-images --repository-name ${SERVICE} --region us-east-1
   ```
3. Re-push image if needed (re-run CI/CD workflow)

### Previous Environment Validation Fails

**Symptoms**:
- Workflow fails at "Check previous environment validation"
- Error: "Image has NOT been tested in previous environment"

**Solutions**:
1. Deploy to previous environment first:
   - For production: deploy to staging first
   - For staging: deploy to dev first
2. Verify image tag exists in previous environment's `image-tags.yaml`

### Deployment Window Blocked

**Symptoms**:
- Production deployment fails
- Error: "Production deployments are blocked during business hours"

**Solutions**:
1. Wait until outside business hours (before 9 AM or after 5 PM EST)
2. Deploy during weekends (anytime allowed)
3. For urgent deployments, temporarily disable window check (not recommended)

## Deployment Execution Issues

### ArgoCD Sync Timeout

**Symptoms**:
- Workflow fails at "Wait for ArgoCD Sync" step
- ArgoCD application not syncing

**Solutions**:
1. Check ArgoCD application status:
   ```bash
   kubectl get application -n argocd
   kubectl describe application ${SERVICE} -n argocd
   ```

2. Check ArgoCD sync status:
   ```bash
   kubectl get application ${SERVICE} -n argocd -o jsonpath='{.status.sync.status}'
   kubectl get application ${SERVICE} -n argocd -o jsonpath='{.status.health.status}'
   ```

3. Manual sync via ArgoCD UI or CLI:
   ```bash
   argocd app sync ${SERVICE}
   ```

4. Check for sync errors:
   ```bash
   kubectl get application ${SERVICE} -n argocd -o yaml | grep -A 10 "conditions"
   ```

### Helm Values Not Updating

**Symptoms**:
- Image tag updated but deployment still using old tag
- ArgoCD shows sync but pods not updated

**Solutions**:
1. Verify Helm values file was updated:
   ```bash
   git log helm/environments/{env}-env/image-tags.yaml
   cat helm/environments/{env}-env/image-tags.yaml
   ```

2. Force ArgoCD refresh:
   ```bash
   argocd app get ${SERVICE} --refresh
   ```

3. Check ArgoCD app source:
   ```bash
   kubectl get application ${SERVICE} -n argocd -o jsonpath='{.spec.source}'
   ```

## Post-Deployment Issues

### Health Checks Fail

**Symptoms**:
- Workflow fails at "Verify Deployment Health" step
- Pods not becoming ready

**Solutions**:
1. Check pod status:
   ```bash
   kubectl get pods -l app=${SERVICE} -n default
   kubectl describe pod ${POD_NAME} -n default
   ```

2. Check pod logs:
   ```bash
   kubectl logs ${POD_NAME} -n default
   kubectl logs ${POD_NAME} -n default --previous  # Previous container
   ```

3. Check events:
   ```bash
   kubectl get events -n default --sort-by='.lastTimestamp' | grep ${SERVICE}
   ```

4. Check resource constraints:
   ```bash
   kubectl top pods -n default
   ```

### Smoke Tests Fail

**Symptoms**:
- Workflow fails at "Run Smoke Tests" step
- Health endpoint not responding

**Solutions**:
1. Verify service is accessible:
   ```bash
   kubectl port-forward svc/${SERVICE} 8080:${PORT} -n default
   curl http://localhost:8080/actuator/health
   ```

2. Check service configuration:
   ```bash
   kubectl get svc ${SERVICE} -n default -o yaml
   kubectl get endpoints ${SERVICE} -n default
   ```

3. Verify health endpoint path:
   - Should be: `/actuator/health`
   - Check Spring Boot Actuator is enabled

4. Check network policies:
   ```bash
   kubectl get networkpolicies -n default
   ```

### High Error Rates

**Symptoms**:
- Metrics validation shows high error rates
- Service returning 5xx errors

**Solutions**:
1. Check application logs for errors:
   ```bash
   kubectl logs -l app=${SERVICE} -n default | grep -i error
   ```

2. Check Prometheus metrics:
   ```bash
   # Query error rate
   curl -s "http://prometheus.monitoring.svc.cluster.local:9090/api/v1/query?query=rate(http_server_requests_seconds_count{application=\"${SERVICE}\",status=~\"5..\"}[5m])"
   ```

3. Check resource usage:
   ```bash
   kubectl top pods -n default
   kubectl describe pod ${POD_NAME} -n default | grep -A 5 "Limits\|Requests"
   ```

4. Consider rollback if errors persist

## General Troubleshooting Commands

### Check Deployment Status

```bash
# Deployment status
kubectl get deployment ${SERVICE}-deployment -n default

# Pod status
kubectl get pods -l app=${SERVICE} -n default

# Service status
kubectl get svc ${SERVICE} -n default
```

### View Logs

```bash
# Current logs
kubectl logs -l app=${SERVICE} -n default --tail=100

# Previous container logs (if crashed)
kubectl logs ${POD_NAME} -n default --previous

# Follow logs
kubectl logs -l app=${SERVICE} -n default -f
```

### Check Resources

```bash
# Resource usage
kubectl top pods -n default

# Resource limits
kubectl describe deployment ${SERVICE}-deployment -n default | grep -A 10 "Limits\|Requests"

# Events
kubectl get events -n default --sort-by='.lastTimestamp' | tail -20
```

### ArgoCD Diagnostics

```bash
# Application status
kubectl get application -n argocd
kubectl describe application ${SERVICE} -n argocd

# Sync status
kubectl get application ${SERVICE} -n argocd -o jsonpath='{.status.sync.status}'

# Health status
kubectl get application ${SERVICE} -n argocd -o jsonpath='{.status.health.status}'

# Conditions (errors)
kubectl get application ${SERVICE} -n argocd -o yaml | grep -A 10 "conditions"
```

## When to Rollback

Consider rolling back if:
- Health checks continue to fail after 5 minutes
- Service is returning 5xx errors
- Pods are crashing repeatedly
- Critical functionality is broken
- Error rates exceed acceptable thresholds

## Getting Help

If issues persist:
1. Check deployment records in `docs/deployments/`
2. Review ArgoCD application logs
3. Check Prometheus/Grafana dashboards
4. Review application logs in Loki
5. Consult team or escalate if critical production issue

## Related Documentation

- [Deployment Process](deployment-process.md)
- [Rollback Procedures](rollback-procedures.md)
- [ArgoCD Sync Failures](argocd-sync-failures.md)
- [Troubleshooting Pod Crashes](troubleshooting-pod-crashes.md)

