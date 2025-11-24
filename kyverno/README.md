# Kyverno Policy Management

This directory contains Kyverno security policies for the multi-environment microservices platform running on EKS.

## Overview

Kyverno is a policy engine designed for Kubernetes that validates, mutates, and generates resources using policies as code. All policies in this repository are managed via GitOps through ArgoCD.

## Directory Structure

```
kyverno/
├── policies/
│   ├── cluster/          # Cluster-wide policies (apply to all namespaces)
│   └── namespace/        # Namespace-specific policies (optional)
├── tests/
│   ├── test-resources/   # Sample resources for testing
│   └── test-policies.sh  # Test script for policy validation
└── README.md             # This file
```

## Policies

### 1. require-cosign-signature
**Type**: ClusterPolicy (validate)  
**Purpose**: Ensures all container images are signed with Cosign using GitHub Actions keyless signing before deployment.

**Key Features**:
- Validates images from ECR registry: `063630846340.dkr.ecr.us-east-1.amazonaws.com/*`
- Uses keyless signing with certificate identity from GitHub Actions workflows
- Verifies certificate identity matches: `https://github.com/yonatandas/Multi-Environment-Microservices/.github/workflows/*`
- Verifies OIDC issuer: `https://token.actions.githubusercontent.com`
- Mutates image references to use digest for immutability

**Exclusions**: kube-system, kyverno, argocd, external-secrets namespaces

### 2. require-semantic-version
**Type**: ClusterPolicy (validate)  
**Purpose**: Prevents use of mutable tags like `latest`, `dev`, `main`, or `master`.

**Allowed Tags**:
- Semantic versions: `v1.0.0`, `v2.3.4`
- Numeric build numbers: `1`, `20`, `123` (matches GitHub Actions `run_number`)

**Blocked Tags**:
- `latest`, `dev`, `main`, `master`
- Any tag containing `dev` or `test` (e.g., `dev-build`, `test-123`)

**Exclusions**: kube-system, kyverno, argocd, external-secrets namespaces

### 3. restrict-ecr-registry
**Type**: ClusterPolicy (validate)  
**Purpose**: Only allows container images from the trusted ECR registry.

**Allowed Registry**: `063630846340.dkr.ecr.us-east-1.amazonaws.com/*`

**Blocked**: All other registries (docker.io, quay.io, gcr.io, etc.)

**Exclusions**: kube-system, kyverno, argocd, external-secrets namespaces

### 4. block-privileged-containers
**Type**: ClusterPolicy (validate)  
**Purpose**: Prevents containers from running with privileged mode or dangerous capabilities.

**Blocked**:
- `securityContext.privileged: true`
- Dangerous capabilities: `SYS_ADMIN`, `NET_ADMIN`, `SYS_RAWIO`, `SYS_MODULE`, `SYS_TIME`
- `allowPrivilegeEscalation: true`

**Exclusions**: kube-system, kyverno, argocd, external-secrets namespaces

### 5. enforce-non-root
**Type**: ClusterPolicy (mutate + validate)  
**Purpose**: Ensures containers run as non-root users.

**Mutation**:
- Adds `securityContext.runAsNonRoot: true` and `runAsUser: 1000` if not specified

**Validation**:
- Rejects Pods with `runAsUser: 0` (root)
- Requires `runAsNonRoot: true` and `runAsUser > 0`

**Exclusions**: kube-system, kyverno, argocd, external-secrets namespaces

### 6. require-resource-limits
**Type**: ClusterPolicy (validate)  
**Purpose**: Ensures all containers have CPU and memory requests and limits defined.

**Required**:
- `resources.requests.cpu`
- `resources.requests.memory`
- `resources.limits.cpu`
- `resources.limits.memory`

**Note**: Your Helm templates already set these in `bankingapp-common/values.yaml`, but this policy enforces them.

**Exclusions**: kube-system, kyverno, argocd, external-secrets namespaces

### 7. require-network-policy
**Type**: ClusterPolicy (validate - Audit mode)  
**Purpose**: Ensures all Pods have a corresponding NetworkPolicy.

**Status**: Currently in audit mode (warns but doesn't block)

**Note**: Your Helm templates already create NetworkPolicies via `bankingapp-common/templates/_networkpolicy.tpl`.

**Exclusions**: kube-system, kyverno, argocd, external-secrets namespaces

### 8. deny-empty-env-vars
**Type**: ClusterPolicy (validate)  
**Purpose**: Prevents containers from having empty environment variable values.

**Blocked**: `env[].value: ""` (empty string)

**Allowed**: `envFrom` (ConfigMaps/Secrets) as values are resolved at runtime

**Exclusions**: kube-system, kyverno, argocd, external-secrets namespaces

### 9. deny-hostpath-mounts
**Type**: ClusterPolicy (validate)  
**Purpose**: Blocks Pods from mounting host filesystem paths.

**Blocked**: `volumes[].hostPath`

**Allowed**: `emptyDir`, `configMap`, `secret`, `persistentVolumeClaim`

**Exclusions**: kube-system, kyverno, argocd, external-secrets namespaces

## Deployment

### Infrastructure (Terraform)

Kyverno is installed via Terraform in `terraform/modules/eks/main.tf`:

```hcl
resource "helm_release" "kyverno" {
  name       = "kyverno"
  namespace  = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  version    = "3.1.0"
  # ... configuration
}
```

**Deployment Order**:
1. EKS Cluster + Node Group
2. External Secrets Operator
3. AWS Load Balancer Controller
4. ArgoCD
5. **Kyverno** (depends on ArgoCD)

### Policies (GitOps via ArgoCD)

Policies are deployed via ArgoCD Applications:

- `gitops/dev/applications/kyverno-policies-dev.yaml`
- `gitops/stag/applications/kyverno-policies-stag.yaml`
- `gitops/prod/applications/kyverno-policies-prod.yaml`

Each Application syncs policies from `kyverno/policies/cluster/` to the cluster.

**Sync Options**:
- `ServerSideApply=true`: Required for ClusterPolicy CRDs
- `automated.prune: true`: Removes policies deleted from Git
- `automated.selfHeal: true`: Re-applies policies if manually modified

## Testing

### Local Testing

1. Install `kyverno-cli`:
   ```bash
   curl -LO "https://github.com/kyverno/kyverno/releases/latest/download/kyverno-cli_v1.12.0_linux_x86_64.tar.gz"
   tar -xzf kyverno-cli_v1.12.0_linux_x86_64.tar.gz
   sudo mv kyverno /usr/local/bin/
   ```

2. Validate policy syntax:
   ```bash
   for policy in kyverno/policies/cluster/*.yaml; do
     kyverno validate "$policy"
   done
   ```

3. Run test script:
   ```bash
   cd kyverno/tests
   ./test-policies.sh
   ```

### CI/CD Testing

The GitHub Actions workflow (`.github/workflows/Microservice-Ci.yaml`) includes a `Validate-Kyverno-Policies` job that:
- Validates policy syntax
- Tests policies against sample resources
- Runs automatically on policy changes

## Troubleshooting

### Policy Violations

When a policy blocks a deployment:

1. **Check ArgoCD Application Status**:
   ```bash
   kubectl get application kyverno-policies-dev -n argocd
   kubectl describe application kyverno-policies-dev -n argocd
   ```

2. **View Policy Violations**:
   ```bash
   kubectl get clusterpolicies
   kubectl describe clusterpolicy <policy-name>
   ```

3. **Check Kyverno Logs**:
   ```bash
   kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno
   ```

4. **Test Policy Against Resource**:
   ```bash
   kyverno test kyverno/tests/ --policy kyverno/policies/cluster/
   ```

### Common Issues

#### 1. Cosign Signature Verification Fails

**Symptom**: Images are blocked with "signature verification failed"

**Causes**:
- Image not signed with Cosign
- Certificate identity mismatch
- OIDC issuer mismatch

**Solution**:
- Ensure images are signed in GitHub Actions workflow
- Verify certificate identity matches: `https://github.com/yonatandas/Multi-Environment-Microservices/.github/workflows/*`
- Check Cosign signing script: `.github/scripts/06-cosign-sign-verify.sh`

#### 2. Image Tag Validation Fails

**Symptom**: Deployment blocked with "tag validation failed"

**Causes**:
- Using `latest`, `dev`, `main`, or `master` tag
- Tag contains `dev` or `test`

**Solution**:
- Use semantic version (`v1.0.0`) or numeric build number (`20`, `123`)
- Update Helm values: `helm/environments/*/values.yaml` or `helm/environments/*/image-tags.yaml`

#### 3. Non-Root Policy Blocks Deployment

**Symptom**: Pod rejected with "runAsUser must be > 0"

**Causes**:
- Missing `securityContext` in Pod spec
- `runAsUser: 0` (root) specified

**Solution**:
- Policy will mutate to add `runAsNonRoot: true` and `runAsUser: 1000`
- If mutation fails, manually add to Helm template: `helm/bankingapp-common/templates/_deployment.tpl`

#### 4. Resource Limits Missing

**Symptom**: Pod rejected with "resources.requests/limits required"

**Causes**:
- Missing `resources` in container spec

**Solution**:
- Ensure Helm values include resources: `helm/bankingapp-common/values.yaml`
- Policy enforces what's already in your templates

### Debugging Commands

```bash
# Check Kyverno pod status
kubectl get pods -n kyverno

# View all ClusterPolicies
kubectl get clusterpolicies

# Describe a specific policy
kubectl describe clusterpolicy require-cosign-signature

# Check policy violations in events
kubectl get events -n default --sort-by='.lastTimestamp' | grep kyverno

# View admission controller logs
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno --tail=100

# Test a resource against policies
kyverno test kyverno/tests/ --policy kyverno/policies/cluster/
```

## Policy Updates

### Adding a New Policy

1. Create policy YAML in `kyverno/policies/cluster/`
2. Follow naming convention: `kebab-case-policy-name.yaml`
3. Add annotations for documentation
4. Test locally: `kyverno validate <policy-file>`
5. Commit and push to Git
6. ArgoCD will automatically sync the policy

### Modifying an Existing Policy

1. Edit policy YAML in `kyverno/policies/cluster/`
2. Validate syntax: `kyverno validate <policy-file>`
3. Test against resources: `kyverno test kyverno/tests/ --policy kyverno/policies/cluster/`
4. Commit and push to Git
5. ArgoCD will automatically sync the updated policy

### Disabling a Policy

1. Set `validationFailureAction: Audit` (warns but doesn't block)
2. Or add namespace to `exclude` list
3. Or delete the policy file (ArgoCD will prune it)

## Integration with Existing Setup

### Helm Charts

Your Helm templates in `helm/bankingapp-common/` already comply with most policies:
- ✅ Resource limits defined in `values.yaml`
- ✅ NetworkPolicies created via `_networkpolicy.tpl`
- ⚠️ SecurityContext not set (will be mutated by `enforce-non-root`)

### GitHub Actions

Your CI/CD pipeline (`.github/workflows/Microservice-Ci.yaml`):
- ✅ Signs images with Cosign keyless signing
- ✅ Uses numeric build numbers (`github.run_number`) as tags
- ✅ Pushes to ECR registry

### ArgoCD

ArgoCD Applications:
- ✅ Sync policies from Git automatically
- ✅ Use ServerSideApply for ClusterPolicy CRDs
- ✅ Self-heal if policies are manually modified

## References

- [Kyverno Documentation](https://kyverno.io/docs/)
- [Kyverno Policies](https://kyverno.io/policies/)
- [Cosign Keyless Signing](https://github.com/sigstore/cosign/blob/main/KEYLESS.md)
- [Kyverno CEL Expressions](https://kyverno.io/docs/writing-policies/cel/)

