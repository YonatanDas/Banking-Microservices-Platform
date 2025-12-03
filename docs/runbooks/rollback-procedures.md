# Rollback Procedures

This document describes how to rollback deployments when issues are detected.

## Automatic Rollback

The deployment workflow automatically rolls back if:
- Post-deployment verification fails
- Health checks fail
- Smoke tests fail

The automatic rollback:
1. Reverts to the previous image tag from Git history
2. Updates Helm values
3. Commits the rollback
4. Triggers ArgoCD sync

## Manual Rollback

### Method 1: Via Deployment Workflow

1. Go to GitHub Actions → "Deploy Service to Environment"
2. Run workflow with:
   - **Service**: Service to rollback
   - **Environment**: Target environment
   - **Image Tag**: Previous known good tag
3. Complete the deployment workflow

### Method 2: Via Git (Direct)

1. Identify the previous image tag:
   ```bash
   # View Git history
   git log helm/environments/{env}-env/image-tags.yaml
   
   # Or check deployment records
   ls docs/deployments/{env}/
   ```

2. Update the image tag:
   ```bash
   # Edit the file
   vi helm/environments/{env}-env/image-tags.yaml
   
   # Update the tag for your service
   # Example:
   # accounts:
   #   image:
   #     tag: 42  # Previous tag
   ```

3. Commit and push:
   ```bash
   git add helm/environments/{env}-env/image-tags.yaml
   git commit -m "rollback: revert {service} to {previous-tag} in {env}"
   git push origin main
   ```

4. ArgoCD will automatically sync the change

### Method 3: Via ArgoCD UI

1. Access ArgoCD UI
2. Find the application for your service
3. Click "History"
4. Select the previous revision
5. Click "Sync" to that revision

## Finding Previous Image Tags

### From Git History

```bash
# View commit history for image tags file
git log helm/environments/prod-env/image-tags.yaml

# View specific commit
git show {commit-hash}:helm/environments/prod-env/image-tags.yaml | grep -A2 "accounts"
```

### From Deployment Records

```bash
# List deployment records
ls docs/deployments/prod/

# View specific deployment record
cat docs/deployments/prod/accounts-2024-01-15T10:30:00Z.md
```

### From ArgoCD

```bash
# Get current deployed image
kubectl get application {service} -n argocd -o jsonpath='{.status.sync.revision}'

# View ArgoCD history
argocd app history {service}
```

## Rollback Verification

After rollback, verify:

1. **ArgoCD Sync**: Check that ArgoCD synced the rollback
   ```bash
   kubectl get application {service} -n argocd
   ```

2. **Deployment Status**: Verify deployment is healthy
   ```bash
   kubectl get deployment {service}-deployment -n default
   kubectl get pods -l app={service} -n default
   ```

3. **Health Checks**: Verify service is responding
   ```bash
   kubectl port-forward svc/{service} 8080:{port} -n default
   curl http://localhost:8080/actuator/health
   ```

4. **Logs**: Check for errors
   ```bash
   kubectl logs -l app={service} -n default --tail=50
   ```

## Emergency Rollback

For critical production issues:

1. **Immediate Action**: Use ArgoCD UI to sync to previous revision
2. **Verify**: Quick health check
3. **Document**: Create rollback record
4. **Investigate**: After service restored, investigate root cause

## Rollback Best Practices

1. **Document rollbacks**: Always document why rollback was necessary
2. **Investigate root cause**: After rollback, investigate what went wrong
3. **Test fixes**: Fix issues in dev/staging before re-deploying
4. **Communicate**: Notify team about rollback
5. **Review**: Conduct post-mortem for production rollbacks

## Related Documentation

- [Deployment Process](deployment-process.md)
- [Troubleshooting Deployments](troubleshooting-deployments.md)

