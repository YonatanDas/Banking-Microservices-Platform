# RBAC & User Management for EKS Cluster

This directory contains Role-Based Access Control (RBAC) configurations for managing user access to the EKS cluster.

## Overview

The EKS cluster uses a combination of:
- **AWS IAM** for cluster authentication (via `aws eks update-kubeconfig`)
- **Kubernetes RBAC** for authorization (Roles, ClusterRoles, RoleBindings)
- **IRSA (IAM Roles for Service Accounts)** for service-to-AWS access
- **ArgoCD Projects** for GitOps access control

## Directory Structure

```
rbac/
├── roles/              # Role definitions
│   ├── cluster/       # Cluster-wide roles
│   └── namespace/     # Namespace-specific roles
├── rolebindings/      # Role bindings (assign roles to users/groups)
├── serviceaccounts/   # Service accounts for applications
└── examples/          # Helper scripts
```

## User Roles

### Cluster-Level Roles

1. **cluster-admin**: Full cluster access (use sparingly)
   - Can manage all resources including RBAC, nodes, namespaces
   - Reserved for cluster administrators

2. **cluster-developer**: Can create/update resources in all namespaces
   - View all resources
   - Create/update/delete deployments, services, configmaps, secrets
   - Manage pods (including exec and logs)
   - Cannot modify RBAC, nodes, or namespaces

3. **cluster-viewer**: Read-only access to all namespaces
   - Can view all resources
   - Can view logs and events
   - Cannot create, update, or delete anything

4. **cluster-operator**: Can manage deployments but not RBAC
   - Similar to developer but cannot modify RBAC resources
   - Can manage application deployments and configurations

### Namespace-Level Roles

1. **namespace-admin**: Full access to specific namespace
   - All permissions scoped to a single namespace
   - Can manage all resources within the namespace

2. **namespace-developer**: Can create/update resources in namespace
   - Same as cluster developer but scoped to specific namespace
   - Useful for environment-specific access (dev, staging, prod)

3. **namespace-viewer**: Read-only access to namespace
   - Can view all resources in the namespace
   - Cannot modify anything

## AWS IAM Integration

Users authenticate to EKS using AWS IAM:

```bash
# Configure kubectl
aws eks update-kubeconfig --name <cluster-name> --region <region>

# Verify access
kubectl get nodes
```

### IAM User Access

Role bindings reference IAM user ARNs:
```yaml
subjects:
  - kind: User
    name: arn:aws:iam::063630846340:user/developer1
```

### IAM Group Access

Role bindings can reference IAM groups:
```yaml
subjects:
  - kind: Group
    name: arn:aws:iam::063630846340:group/eks-developers
```

All users in the group inherit the permissions.

## Granting Access

### To an IAM User

1. Add user to AWS IAM group with EKS access policy (if using groups)
2. Create or update RoleBinding in `rolebindings/cluster/` or `rolebindings/namespace/`
3. Apply via GitOps (ArgoCD) or manually:
   ```bash
   kubectl apply -f access/rbac/rolebindings/cluster/developer-users.yaml
   ```

### To an IAM Group

1. Create RoleBinding that references IAM group ARN
2. All users in the group automatically inherit permissions
3. Apply via GitOps or manually

### Using Helper Scripts

```bash
# Grant cluster developer access to a user
./examples/grant-access-to-user.sh arn:aws:iam::063630846340:user/john.doe cluster-developer

# Grant access to an IAM group
./examples/grant-access-to-group.sh arn:aws:iam::063630846340:group/developers cluster-developer
```

## Service Accounts

Service accounts are used for:
- **Application workloads**: Managed per-service in Helm charts
- **CI/CD operations**: Defined in `serviceaccounts/ci-cd-sa.yaml`
- **Monitoring tools**: Defined in `serviceaccounts/monitoring-sa.yaml`

Service accounts can be annotated with IRSA role ARNs for AWS access:
```yaml
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/IRSA-ROLE-NAME
```

## Deployment

RBAC configurations are deployed via ArgoCD Applications:

- `gitops/dev/applications/access/rbac-dev.yaml` - Deploy RBAC to dev cluster
- `gitops/stag/applications/access/rbac-stag.yaml` - Deploy RBAC to staging cluster
- `gitops/prod/applications/access/rbac-prod.yaml` - Deploy RBAC to production cluster

Each application:
- Syncs from `access/rbac/` directory
- Uses `ServerSideApply=true` for cluster-scoped resources
- Deploys to `kube-system` namespace (for cluster-scoped resources)
- Enables automated sync and self-healing

## Testing Permissions

Use the test script to verify user permissions:

```bash
./examples/test-rbac-permissions.sh
```

Or manually test:

```bash
# Test as a user (after configuring kubectl)
kubectl auth can-i create deployments --all-namespaces
kubectl auth can-i delete pods
kubectl auth can-i get secrets
```

## Best Practices

1. **Least Privilege**: Grant minimum permissions required
2. **Use Namespace Roles**: Prefer namespace-scoped roles over cluster roles when possible
3. **Group Management**: Use IAM groups for easier user management
4. **Regular Audits**: Review role bindings periodically
5. **Documentation**: Document why specific permissions are granted

## Troubleshooting

### User Cannot Access Cluster

1. Verify IAM user/group has EKS access policy
2. Check RoleBinding exists and references correct IAM ARN
3. Verify kubectl is configured: `aws eks update-kubeconfig --name <cluster>`
4. Test access: `kubectl get nodes`

### Permission Denied Errors

1. Check user's role: `kubectl auth can-i <verb> <resource>`
2. Verify RoleBinding includes the user
3. Check if namespace-scoped role is used (may need cluster role)
4. Review role permissions in `roles/` directory

### Service Account Issues

1. Verify ServiceAccount exists: `kubectl get sa -n <namespace>`
2. Check IRSA annotation if AWS access is needed
3. Verify pod is using the ServiceAccount

## Integration with Existing Setup

### Helm Charts

Service accounts for applications are managed in Helm charts:
- `helm/bankingapp-common/templates/_serviceaccount.tpl`
- Per-service ServiceAccounts defined in `helm/environments/*/values.yaml`

### ArgoCD

ArgoCD projects already allow RBAC resources:
- `clusterResourceWhitelist` includes `ClusterRole` and `ClusterRoleBinding`
- `namespaceResourceWhitelist` includes `Role` and `RoleBinding`

### IRSA

IRSA (IAM Roles for Service Accounts) is configured via:
- Terraform: `infra/terraform/modules/iam/irsa/`
- ServiceAccount annotations in Helm charts

## References

- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [EKS User Access](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html)
- [IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

