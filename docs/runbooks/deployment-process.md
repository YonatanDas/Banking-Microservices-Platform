# Deployment Process

This document describes the production-grade deployment process for services to staging and production environments.

## Overview

The deployment process follows a staged approach:
1. **Development**: Automatic deployment on merge to `main`
2. **Staging**: Manual deployment with validation
3. **Production**: Manual deployment with approval gates and strict validation

## Deployment Workflow

### 1. Pre-Deployment Validation

Before any deployment, the following validations occur:

#### Image Validation
- ✅ **Image Signature**: Verifies Cosign signature exists
- ✅ **Image Existence**: Confirms image exists in ECR
- ✅ **Previous Environment**: Validates image was tested in previous environment

#### Deployment Window Validation
- **Staging**: No restrictions
- **Production**: Blocked during business hours (9 AM - 5 PM EST, Monday-Friday)

### 2. Deployment Execution

1. Update Helm values with new image tag
2. Commit changes to Git
3. ArgoCD automatically syncs the changes
4. Wait for ArgoCD sync completion (timeout: 5 minutes)

### 3. Post-Deployment Verification

After deployment, the following verifications occur:

#### Health Checks
- ✅ Kubernetes deployment status (all pods ready)
- ✅ Pod readiness (no crash loops)
- ✅ Health endpoint checks (`/actuator/health`)

#### Smoke Tests
- ✅ Service health endpoint responds
- ✅ Service returns "UP" status

#### Metrics Validation
- ✅ HTTP error rates within acceptable threshold
- ✅ Pod restart counts checked
- ✅ Resource usage monitored

### 4. Deployment Records

All deployments create audit trail records in `docs/deployments/{environment}/` with:
- Service name and environment
- Image tag deployed
- Deployment timestamp
- Deployed by (user/actor)
- Deployment reason
- Git commit and workflow run information

## Manual Deployment Process

### Deploying to Staging

1. Go to GitHub Actions → "Deploy Service to Environment"
2. Click "Run workflow"
3. Select:
   - **Service**: Choose service (accounts, cards, loans, gateway)
   - **Environment**: `stag`
   - **Image Tag**: Leave empty to use latest from dev, or specify tag
   - **Reason**: Optional deployment reason
4. Click "Run workflow"
5. Wait for workflow completion

### Deploying to Production

1. Ensure the image has been tested in staging first
2. Go to GitHub Actions → "Deploy Service to Environment"
3. Click "Run workflow"
4. Select:
   - **Service**: Choose service
   - **Environment**: `prod`
   - **Image Tag**: Leave empty to use latest from staging, or specify tag
   - **Reason**: **Required** - provide change ticket or reason
5. Review and approve the deployment (if GitHub Environments require approval)
6. Wait for workflow completion

**Note**: Production deployments are blocked during business hours (9 AM - 5 PM EST, Monday-Friday).

## Environment Promotion Strategy

### Recommended Flow

```
Development → Staging → Production
   (auto)      (manual)    (manual + approval)
```

### Promotion Rules

1. **Dev → Staging**: 
   - Image must be built and tested in dev
   - Can deploy any time

2. **Staging → Production**:
   - Image **must** be deployed to staging first
   - Image **must** be tested in staging
   - Deployment blocked during business hours
   - Requires approval (if configured in GitHub Environments)

## Image Tag Resolution

### Automatic Resolution

If no image tag is provided:
- **Staging**: Uses latest tag from `dev` environment
- **Production**: Uses latest tag from `staging` environment

### Manual Tag Specification

You can specify an exact image tag (e.g., `123`, `v1.2.3`, `main-abc123`)

## Rollback Process

### Automatic Rollback

If deployment fails during post-deployment verification, the workflow automatically:
1. Reverts to the previous image tag
2. Updates Helm values
3. Commits the rollback
4. Triggers ArgoCD sync
5. Notifies team

### Manual Rollback

To manually rollback:

1. Identify the previous image tag (check Git history or deployment records)
2. Run the deployment workflow with the previous tag
3. Or manually update `helm/environments/{env}-env/image-tags.yaml` and commit

Example:
```bash
# Find previous tag
git log helm/environments/prod-env/image-tags.yaml

# Update to previous tag manually or via workflow
```

## Troubleshooting

### Deployment Fails Pre-Validation

**Issue**: Image signature validation fails
- **Solution**: Ensure image was signed during CI/CD build process
- **Check**: Verify Cosign signing step completed in build workflow

**Issue**: Image doesn't exist in ECR
- **Solution**: Ensure image was built and pushed successfully
- **Check**: Verify ECR repository and image tag

**Issue**: Previous environment validation fails
- **Solution**: Deploy to previous environment first (stag → prod requires stag deployment)
- **Check**: Verify image tag exists in previous environment's `image-tags.yaml`

**Issue**: Deployment window blocked (production)
- **Solution**: Wait until outside business hours (before 9 AM or after 5 PM EST)
- **Check**: Current time in EST timezone

### Deployment Fails During Sync

**Issue**: ArgoCD sync timeout
- **Solution**: Check ArgoCD application status manually
- **Check**: `kubectl get application -n argocd`
- **Action**: Manual sync may be required via ArgoCD UI

### Deployment Fails Post-Verification

**Issue**: Health checks fail
- **Solution**: Check pod logs and events
- **Command**: `kubectl logs -l app={service} -n default`
- **Command**: `kubectl describe deployment {service}-deployment -n default`

**Issue**: Smoke tests fail
- **Solution**: Verify service health endpoint is accessible
- **Check**: `curl http://{service}.default.svc.cluster.local:{port}/actuator/health`

### Rollback Issues

**Issue**: Rollback fails
- **Solution**: Manually update Helm values file
- **Action**: Edit `helm/environments/{env}-env/image-tags.yaml` and commit

## Best Practices

1. **Always test in staging first** before promoting to production
2. **Provide meaningful deployment reasons** for audit trail
3. **Monitor deployment records** in `docs/deployments/`
4. **Review ArgoCD sync status** after deployment
5. **Check metrics and logs** post-deployment
6. **Schedule production deployments** outside business hours when possible
7. **Keep deployment records** for compliance and troubleshooting

## Related Documentation

- [Rollback Procedures](rollback-procedures.md)
- [Troubleshooting Deployments](troubleshooting-deployments.md)
- [ArgoCD Sync Failures](../runbooks/argocd-sync-failures.md)

