# GitOps with Argo CD

## Purpose in this project

Argo CD implements GitOps by continuously synchronizing Kubernetes resources from Git. It monitors the `gitops/` directory and `helm/environments/` charts, automatically applying changes to the EKS cluster. Deployments are declarative, auditable, and self-healing across dev, staging, and production environments.

## Folder structure overview

```
gitops/
├── dev/
│   ├── applications/               # Argo CD Application manifests
│   │   ├── banking-app-dev.yaml   # Main banking app (dev environment chart)
│   │   ├── prometheus-operator-dev.yaml
│   │   ├── grafana-dashboards-dev.yaml
│   │   ├── loki-stack-dev.yaml
│   │   ├── promtail-dev.yaml
│   │   ├── tempo-dev.yaml
│   │   ├── opentelemetry-collector-dev.yaml
│   │   └── kyverno-policies-dev.yaml
│   └── appprojects/
│       └── banking-dev-project.yaml  # Argo CD Project (RBAC, source restrictions)
├── stag/                           # Staging environment applications
└── prod/                           # Production environment applications
```

**Key entry points**: `gitops/{dev,stag,prod}/applications/*.yaml` (Argo CD watches these)

## How it works / design

### App-of-apps pattern

Each environment uses an **app-of-apps** structure:
- **Root application**: `banking-app-{env}.yaml` points to `helm/environments/{env}-env/` chart
- **Monitoring applications**: Separate Argo CD Applications for Prometheus, Grafana, Loki, Tempo, OpenTelemetry Collector
- **Policy applications**: `kyverno-policies-{env}.yaml` syncs Kyverno ClusterPolicies from `kyverno/policies/cluster/`

### Automated synchronization

Argo CD Applications are configured with:
- **Automated sync**: `syncPolicy.automated.prune: true` and `selfHeal: true` ensure Git is the source of truth
- **Sync options**: `CreateNamespace=true`, `PrunePropagationPolicy=foreground`, `ServerSideApply=true` (for ClusterPolicies)
- **Ignore differences**: HPA replica changes, Secret data (updated by ESO), Service annotations (added by ALB Controller) are ignored to prevent drift

### Multi-environment management

- **Environment isolation**: Separate Argo CD Applications per environment prevent cross-environment deployments
- **Project-based RBAC**: `banking-{env}-project.yaml` restricts source repositories and destination namespaces
- **Source control**: All applications reference the same Git repository (`YonatanDas/Banking-Microservices-Platform`) with branch/path filtering

### Integration with Terraform

Argo CD is installed via Terraform (`terraform/modules/eks/argocd.tf`) as a Helm release, ensuring infrastructure-as-code consistency. After cluster provisioning, Argo CD Applications are created manually or via `kubectl apply` to bootstrap GitOps.

## Key highlights

- **Declarative deployments**: All desired state defined in Git with version control, rollbacks, and audit trails
- **Self-healing**: Argo CD automatically reconciles manual changes so cluster state matches Git
- **Multi-environment consistency**: Same GitOps pattern across dev/staging/prod reduces configuration drift
- **Separation of concerns**: Application deployments, monitoring stack, and security policies managed as separate Argo CD Applications
- **Automated sync**: Sync, prune, and self-heal keep Git as the single source of truth
- **RBAC enforcement**: Argo CD Projects restrict which repositories and namespaces applications can deploy to

## How to use / extend

### Deploy an application via GitOps

1. **Create/update Argo CD Application manifest** in `gitops/{env}/applications/`
2. **Commit and push** to Git
3. **Argo CD detects change** and syncs automatically (or trigger manual sync via UI/CLI)

### Add a new Argo CD Application

Create `gitops/{env}/applications/{app-name}-{env}.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {app-name}-{env}
  namespace: argocd
spec:
  project: banking-{env}-project
  source:
    repoURL: https://github.com/YonatanDas/Banking-Microservices-Platform.git
    targetRevision: main
    path: {path-to-manifests-or-chart}
  destination:
    server: https://kubernetes.default.svc
    namespace: {target-namespace}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Manual sync (if needed)

```bash
argocd app sync banking-app-dev
argocd app get banking-app-dev
```

### Rollback

```bash
argocd app rollback banking-app-dev {revision-hash}
```

Or revert the Git commit and let Argo CD auto-sync.

### Troubleshooting

- **Check application status**: `kubectl get application -n argocd`
- **View sync history**: `argocd app history banking-app-dev`
- **Inspect sync errors**: `kubectl describe application banking-app-dev -n argocd`

