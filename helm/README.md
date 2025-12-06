# Helm Charts

Helm charts package and deploy the banking microservices to Kubernetes. The architecture uses a **service-per-chart** pattern with shared templates (`bankingapp-common`) and environment-specific value overrides.

## Chart Structure

**Service-per-Chart**: Each microservice (accounts, cards, loans, gateway) has its own Helm chart in `helm/bankingapp-services/{service}/`. Charts depend on `bankingapp-common` for shared templates.

**Shared Templates**: `helm/bankingapp-common/` provides reusable templates:
- `_deployment.tpl` - Deployment with security contexts, probes, OpenTelemetry
- `_service.tpl` - Kubernetes Service
- `_serviceaccount.tpl` - ServiceAccount with IRSA annotations
- `_networkpolicy.tpl` - NetworkPolicy for zero-trust networking
- `_hpa.tpl` - HorizontalPodAutoscaler
- `_pdb.tpl` - PodDisruptionBudget
- `_servicemonitor.tpl` - Prometheus ServiceMonitor
- `_denyAllIngress.tpl` / `_denyAllEgress.tpl` - Default deny policies

**Environment Charts**: `helm/environments/{env}-env/` compose all service charts and provide environment-specific values. These are consumed by Argo CD for GitOps deployments.

## Best Practices Implemented

### Resource Management

**Resource Requests/Limits**: All containers define CPU and memory requests/limits in `values.yaml`. Defaults provided in `bankingapp-common/values.yaml`, overridable per service.

**Horizontal Pod Autoscaling (HPA)**: Configured via `_hpa.tpl` template:
- Scales based on CPU and memory utilization (default: 70% target)
- Min replicas: 1-2, Max replicas: 3-6 (configurable per service)
- Enabled via `hpa.enabled: true` in values

**PodDisruptionBudgets (PDB)**: Defined in `_pdb.tpl` to ensure minimum available pods during voluntary disruptions (node drains, cluster upgrades).

### Security Contexts

**Container Security**: All containers run with:
- `runAsNonRoot: true` (default: user ID 1000)
- `allowPrivilegeEscalation: false`
- `capabilities.drop: [ALL]` (no capabilities granted)

**Init Container Security**: OpenTelemetry agent download init container uses same security context restrictions.

### Network Policies

**Zero-Trust Networking**: NetworkPolicies enforce explicit ingress/egress rules:
- **Ingress**: Services only accept traffic from gateway (except gateway itself, which accepts all)
- **Egress**: Services can communicate with:
  - Other allowed services (service-to-service allowlist)
  - Monitoring namespace (for metrics/logs/traces)
  - DNS (UDP 53) and HTTPS (TCP 443) for external dependencies
- **Gateway**: Only gateway has `denyAllEgress: false` to allow external API calls

**Network Policy Template**: `_networkpolicy.tpl` generates policies based on `networkpolicy.allowFromServices` and `networkpolicy.allowToServices` values.

### Health Probes

**Liveness Probe**: HTTP GET on `/actuator/health/liveness` (or configurable path):
- `initialDelaySeconds: 30`
- `periodSeconds: 40`
- `timeoutSeconds: 5`
- `failureThreshold: 3`

**Readiness Probe**: HTTP GET on `/actuator/health/readiness` (or configurable path):
- `initialDelaySeconds: 60`
- `periodSeconds: 5`
- `timeoutSeconds: 5`
- `failureThreshold: 3`

### Configuration Management

**ConfigMaps**: Shared configuration (Spring profiles, Java options, OpenTelemetry endpoints) templated in environment charts and injected via `envFrom`.

**External Secrets**: Database credentials managed via External Secrets Operator. `ExternalSecret` and `ClusterSecretStore` resources created in environment charts.

**Image Tags**: Managed in `helm/environments/{env}-env/image-tags.yaml`, updated by CI/CD or Argo CD Image Updater.

### Service Accounts & IRSA

**IRSA Integration**: ServiceAccounts annotated with AWS IAM role ARNs:
```yaml
annotations:
  eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/service-role
```

**RDS Access**: Services requiring database access have dedicated IRSA roles with RDS access permissions.

### Observability

**ServiceMonitors**: Each service exposes a Prometheus ServiceMonitor for metrics scraping from `/actuator/prometheus` endpoint.

**OpenTelemetry**: Java agent injected as init container, configured via environment variables:
- `OTEL_SERVICE_NAME`: Service name
- `OTEL_EXPORTER_OTLP_ENDPOINT`: Collector endpoint
- `JAVA_TOOL_OPTIONS`: Java agent instrumentation

## Integration with CI/CD

**Chart Linting**: GitHub Actions workflow (`infra-helm-lint.yaml`) validates all charts with `helm lint` and builds dependencies.

**Image Updates**: CI/CD pipelines update `image-tags.yaml` files after successful image builds. Argo CD syncs these changes automatically.

## Integration with GitOps

**Argo CD Consumption**: Environment charts (`helm/environments/{env}-env/`) are consumed by Argo CD Applications. Argo CD syncs Helm releases from Git.

**Value Files**: Argo CD Applications reference both `values.yaml` and `image-tags.yaml` as Helm value files.

**Auto-Sync**: Changes to Helm charts in Git trigger Argo CD automatic sync (if enabled).

## Adding a New Service

1. Copy `helm/bankingapp-services/_template/values.yaml` to `helm/bankingapp-services/{service}/values.yaml`
2. Update service-specific values (ports, network policies, service account)
3. Create `Chart.yaml` with dependency on `bankingapp-common`
4. Create `templates/include-common.yaml` to include shared templates
5. Add service to `helm/environments/*-env/Chart.yaml` dependencies
6. Add service configuration to `helm/environments/*-env/values.yaml`

The service discovery workflow can auto-generate these files for new services.
