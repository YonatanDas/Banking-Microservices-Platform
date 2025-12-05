# Helm Charts

## Purpose in this project

Helm charts package and deploy the banking microservices to Kubernetes. The architecture uses a **service-per-chart** pattern with shared templates (`bankingapp-common`) and environment-specific value overrides. Charts are consumed by Argo CD for GitOps-driven deployments.

## Folder structure overview

```
helm/
├── bankingapp-common/              # Shared Helm templates (DRY principle)
│   ├── templates/
│   │   ├── _deployment.tpl         # Deployment template with HPA, probes
│   │   ├── _service.tpl            # Service template
│   │   ├── _serviceaccount.tpl     # ServiceAccount with IRSA annotations
│   │   ├── _networkpolicy.tpl     # NetworkPolicy (zero-trust networking)
│   │   ├── _hpa.tpl                # HorizontalPodAutoscaler
│   │   ├── _servicemonitor.tpl     # Prometheus ServiceMonitor
│   │   ├── _denyAllIngress.tpl     # Default deny ingress policy
│   │   └── _denyAllEgress.tpl      # Default deny egress policy
│   └── values.yaml                 # Default values (resources, probes, etc.)
├── bankingapp-services/
│   ├── accounts/                   # Accounts service chart
│   ├── cards/                      # Cards service chart
│   ├── loans/                      # Loans service chart
│   └── gateway/                    # Gateway service chart
│       ├── Chart.yaml
│       ├── values.yaml             # Service-specific overrides
│       └── templates/
│           └── ingress.yaml        # ALB Ingress (gateway only)
└── environments/
    ├── dev-env/                    # Dev environment app-of-apps chart
    ├── stag-env/                   # Staging environment chart
    └── prod-env/                   # Production environment chart
        ├── Chart.yaml
        ├── values.yaml             # Environment-specific values
        ├── image-tags.yaml         # Image tag overrides
        └── templates/
            ├── externalsecret.yaml # ExternalSecret for DB credentials
            └── secretstore.yaml    # ClusterSecretStore for ESO
```

**Key entry points**: `helm/environments/{dev,stag,prod}-env/values.yaml` (consumed by Argo CD)

## How it works / design

### Service-per-chart architecture

Each microservice (`accounts`, `cards`, `loans`, `gateway`) has its own Helm chart that:
- **Depends on `bankingapp-common`**: Inherits shared templates for Deployment, Service, ServiceAccount, NetworkPolicy, HPA
- **Defines service-specific values**: Port numbers, resource limits, ingress configuration (gateway only)
- **Enables independent versioning**: Each service can be updated/deployed separately

### Shared template library (`bankingapp-common`)

The `bankingapp-common` chart provides reusable templates:
- **Deployment**: Includes liveness/readiness probes, resource limits, security context, OpenTelemetry sidecar injection
- **ServiceAccount**: Annotates with IRSA role ARN for AWS IAM integration
- **NetworkPolicy**: Enforces zero-trust networking (gateway → services, service-to-service allowlists, DNS/443 egress)
- **HPA**: Autoscales based on CPU/memory (targets 70% utilization, scales 2-6 replicas)
- **ServiceMonitor**: Exposes Prometheus scraping endpoints (`/actuator/prometheus`)

### Environment charts (app-of-apps pattern)

Environment charts (`dev-env`, `stag-env`, `prod-env`) compose all services:
- **References service charts**: Uses `dependencies` in `Chart.yaml` to include all microservice charts
- **Templates ExternalSecrets**: Creates `ExternalSecret` and `ClusterSecretStore` resources for AWS Secrets Manager integration
- **Environment-specific overrides**: Sets replica counts, IRSA role ARNs, image tags, OpenTelemetry endpoints per environment
- **Consumed by Argo CD**: Argo CD Applications point to these charts for GitOps synchronization

### Configuration management

- **ConfigMaps**: Shared configuration (Spring profiles, Java options, OTEL endpoints) templated in environment charts
- **ExternalSecrets**: Database credentials pulled from AWS Secrets Manager via External Secrets Operator
- **Image tags**: Managed in `image-tags.yaml` files, updated by CI/CD or Argo CD Image Updater

## Key highlights

- **DRY principle**: Shared templates eliminate duplication across 4 microservices
- **Zero-trust networking**: NetworkPolicies enforce explicit ingress/egress rules, blocking unauthorized pod-to-pod communication
- **Autoscaling**: HPAs scale services based on CPU/memory metrics
- **IRSA integration**: ServiceAccounts annotated with AWS IAM role ARNs for least-privilege access to RDS and Secrets Manager
- **Observability**: ServiceMonitors and OpenTelemetry sidecar injection for Prometheus scraping and distributed tracing
- **GitOps-friendly**: Environment charts designed for Argo CD consumption with declarative deployments

## How to use / extend

### Deploy a service manually (for testing)

```bash
helm install accounts ./helm/bankingapp-services/accounts \
  --namespace default \
  -f ./helm/environments/dev-env/values.yaml \
  -f ./helm/environments/dev-env/image-tags.yaml
```

### Update image tags

Edit `helm/environments/{env}-env/image-tags.yaml`:
```yaml
accounts:
  image:
    tag: "v1.2.0"
```

Argo CD will automatically sync the change.

### Add a new microservice

1. **Copy template**: Copy `helm/bankingapp-services/_template/values.yaml` to `helm/bankingapp-services/<new-service>/values.yaml`
2. **Update service values**: Replace all `{placeholder}` values with actual service-specific values:
   - Service identification (deploymentName, serviceName, appLabel, appName)
   - Port numbers (servicePort, containerPort)
   - Network policy (allowFromServices, allowToServices, targetPorts)
   - Service account (if different from defaults)
3. **Create Chart.yaml**: Create `helm/bankingapp-services/<new-service>/Chart.yaml` with dependency on `bankingapp-common`:
   ```yaml
   apiVersion: v2
   name: <new-service>
   description: A Helm chart for Kubernetes
   type: application
   version: 0.1.0
   appVersion: "1.0.0"
   dependencies:
     - name: bankingapp-common
       version: 0.1.0
       repository: "file://../../bankingapp-common"
   ```
4. **Create templates**: Create `helm/bankingapp-services/<new-service>/templates/include-common.yaml` to include shared templates (copy from existing service)
5. **Add to environments**: Add service to `helm/environments/*-env/Chart.yaml` dependencies
6. **Configure environments**: Add service configuration to `helm/environments/*-env/values.yaml`

### Standard values.yaml structure

All service charts follow a uniform structure for consistency and maintainability. The standard structure includes:

1. **Service Identification**: deploymentName, serviceName, appLabel, appName, optional ecrRepositoryName
2. **Replication**: replicaCount
3. **Image Configuration**: repository (computed), tag (env override), pullPolicy
4. **Service Endpoints**: servicePort, containerPort, service definition
5. **Network Policy**: Zero-trust networking configuration
6. **Service Account**: Optional overrides for IRSA and RDS access
7. **Ingress**: Gateway-only configuration
8. **Autoscaling**: HPA configuration
9. **Health Probes**: Standardized liveness and readiness probes
10. **Resources**: CPU and memory requests/limits
11. **Secrets**: Secret name (env override)

**Template Reference**: See `helm/bankingapp-services/_template/values.yaml` for the complete standard structure with documentation.

**Service-Specific Differences**: 
- **Ports**: Each service has unique port numbers
- **Network Policies**: Service-to-service communication patterns differ
- **Gateway**: Only gateway has ingress enabled and denyAllEgress: false
- **Service Account**: Services without RDS access set needsRdsAccess: false

**Probe Timing Standardization**: All services use consistent probe timings:
- Liveness: `periodSeconds: 40`, `initialDelaySeconds: 30`
- Readiness: `initialDelaySeconds: 60`, `periodSeconds: 5`

### Modify shared templates

Edit `helm/bankingapp-common/templates/*.tpl` – changes apply to all services using the common chart.

