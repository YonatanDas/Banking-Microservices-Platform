# Observability & Monitoring Stack

## Purpose in this project

The monitoring stack provides metrics, logs, and traces for the banking microservices platform: **Prometheus** for metrics, **Grafana** for visualization, **Loki** for log aggregation, and **Tempo** for distributed tracing. All components are deployed via Helm charts and managed by Argo CD.

## Folder structure overview

```
08-monitoring/
├── namespace.yaml                    # Monitoring namespace definition
├── prometheus-operator/
│   ├── Chart.yaml
│   └── values/
│       ├── dev.yaml                 # Dev environment Prometheus config
│       ├── prod.yaml
│       └── staging.yaml
├── loki/
│   ├── Chart.yaml
│   ├── templates/
│   └── values/
│       ├── dev.yaml                 # Loki storage (S3) and retention config
│       ├── prod.yaml
│       └── staging.yaml
├── promtail/
│   ├── Chart.yaml
│   └── values/
│       ├── dev.yaml                 # Promtail scraping config
│       ├── prod.yaml
│       └── staging.yaml
├── tempo/
│   ├── Chart.yaml
│   └── values/
│       └── dev.yaml                 # Tempo trace storage config
├── opentelemetry-collector/
│   ├── Chart.yaml
│   ├── config.yaml                  # Base OTLP receiver/processor config
│   ├── config-dev.yaml              # Environment-specific pipelines
│   ├── config-prod.yaml
│   └── values/
│       ├── dev.yaml
│       ├── prod.yaml
│       └── staging.yaml
└── dashboards/
    ├── dev/
    │   ├── application-overview.yaml
    │   └── distributed-tracing.yaml
    ├── prod/                         # Grafana dashboard JSON files
    └── staging/
```

**Key entry points**: Argo CD Applications in `07-gitops/{env}/applications/` sync these Helm charts

## How it works / design

### Metrics: Prometheus Operator

- **Prometheus Operator**: Installed via Helm, manages Prometheus, Alertmanager, and ServiceMonitor CRDs
- **Service scraping**: ServiceMonitors (defined in `06-helm/bankingapp-common/templates/_servicemonitor.tpl`) scrape `/actuator/prometheus` endpoints from Spring Boot services
- **Multi-environment**: Separate Prometheus instances per environment (dev/staging/prod) with environment-specific retention and storage configs
- **Grafana integration**: Grafana datasources automatically discover Prometheus instances

### Dashboards: Grafana

- **Application dashboards**: Pre-configured dashboards for Spring Boot metrics (JVM, HTTP, business metrics)
- **Distributed tracing**: Grafana Tempo datasource enables trace exploration and service dependency graphs
- **Multi-environment**: Separate dashboard sets per environment (dev/staging/prod) with environment-specific queries


<img src="../../11-docs/diagrams/grafana-dashboard-k8s.png" alt="Grafana Dashboard" width="800" />


### Logs: Loki + Promtail

- **Loki**: Centralized log aggregation, stores logs in S3 (configured via Terraform `monitoring` module)
- **Promtail**: DaemonSet that scrapes pod logs and forwards to Loki
- **Log labels**: Promtail labels logs by namespace, pod, container for efficient querying
- **S3 backend**: Loki uses S3 for durable, scalable log storage (IRSA role for S3 access)

### Traces: Tempo + OpenTelemetry Collector

- **Tempo**: Distributed tracing backend, stores traces in object storage
- **OpenTelemetry Collector**: Receives OTLP traces from microservices, processes and forwards to Tempo
- **OTEL instrumentation**: Spring Boot services inject OpenTelemetry Java Agent (configured in Helm values) to emit traces
- **Trace pipeline**: Services → OTEL Collector (gRPC 4317) → Tempo → Grafana visualization


### Integration with microservices

- **ServiceMonitors**: Each microservice exposes a ServiceMonitor for Prometheus scraping
- **OpenTelemetry sidecar**: Helm charts inject OTEL Java Agent as init container, configured via `values.yaml`
- **NetworkPolicies**: Monitoring namespace allowed in NetworkPolicy egress rules for metrics/logs/traces collection

## Key highlights

- **Metrics, logs, and traces**: Provides visibility into microservices health and performance
- **GitOps-managed**: All monitoring components deployed via Argo CD with version-controlled configuration
- **Multi-environment isolation**: Separate Prometheus/Loki/Tempo instances per environment prevent cross-environment data leakage
- **Cost-optimized storage**: Loki uses S3 for log storage; Tempo uses object storage for traces
- **OpenTelemetry standard**: OTEL Collector and Java Agent provide vendor-agnostic observability
- **High availability**: Prometheus Operator provides retention policies and alerting integration

## How to use / extend

### Access Grafana

```bash
kubectl port-forward -n monitoring svc/prometheus-operator-grafana 3000:80
# Open http://localhost:3000 (default: admin/prom-operator)
```

### Query Prometheus

```bash
kubectl port-forward -n monitoring svc/prometheus-operator-kube-p-prometheus 9090:9090
# Open http://localhost:9090
```

### Add a new dashboard

1. Create dashboard JSON in `08-monitoring/dashboards/{env}/`
2. Argo CD Application `grafana-dashboards-{env}` syncs ConfigMap with dashboard
3. Grafana auto-discovers dashboards from ConfigMap

### Modify scraping configuration

Edit `08-monitoring/prometheus-operator/values/{env}.yaml`:
```yaml
prometheus:
  prometheusSpec:
    retention: 30d
    scrapeInterval: 30s
```

### Add log labels

Edit `08-monitoring/promtail/values/{env}.yaml` to add custom labels for log filtering in Grafana.

### Configure trace sampling

Edit `06-helm/environments/{env}-env/values.yaml`:
```yaml
global:
  otel:
    sampling: 0.1  # 10% trace sampling
```

