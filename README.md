# Multi-Environment Banking Platform on AWS EKS

[![CI Status](https://github.com/YonatanDas/Banking-Microservices-Platform/actions/workflows/Microservice-Ci.yaml/badge.svg?branch=main)](https://github.com/YonatanDas/Banking-Microservices-Platform/actions/workflows/Microservice-Ci.yaml)
## 🛠️ Technology Stack

![Terraform](https://img.shields.io/badge/Terraform-1.6+-623CE4?style=flat-square&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat-square&logo=amazon-aws&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white)
![EKS](https://img.shields.io/badge/EKS-FF9900?style=flat-square&logo=amazon-aws&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
![Argo CD](https://img.shields.io/badge/Argo%20CD-EF7B4D?style=flat-square&logo=argo&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat-square&logo=helm&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?style=flat-square&logo=github-actions&logoColor=white)
![Trivy](https://img.shields.io/badge/Trivy-1904DA?style=flat-square&logo=aqua-security&logoColor=white)
![Cosign](https://img.shields.io/badge/Cosign-1E88E5?style=flat-square&logo=kubernetes&logoColor=white)
![Checkov](https://img.shields.io/badge/Checkov-502DF2?style=flat-square&logo=bridgecrew&logoColor=white)
![tfsec](https://img.shields.io/badge/tfsec-3C873A?style=flat-square&logo=terraform&logoColor=white)
![ESO](https://img.shields.io/badge/ESO-4A90E2?style=flat-square&logo=kubernetes&logoColor=white)
![Kyverno](https://img.shields.io/badge/Kyverno-326CE5?style=flat-square&logo=kubernetes&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=flat-square&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat-square&logo=grafana&logoColor=white)
![Loki](https://img.shields.io/badge/Loki-F46800?style=flat-square&logo=grafana&logoColor=white)
![Tempo](https://img.shields.io/badge/Tempo-F46800?style=flat-square&logo=grafana&logoColor=white)
![OpenTelemetry](https://img.shields.io/badge/OpenTelemetry-000000?style=flat-square&logo=opentelemetry&logoColor=white)

> **Production-ready cloud-native platform** transforming a legacy Docker Compose application into a scalable, secure, multi-environment Kubernetes platform on AWS with full GitOps automation, security controls, and observability.

---

## 👔 For Recruiters & Hiring Managers

**TL;DR**: This is a production-ready, cloud-native DevOps platform demonstrating enterprise-level skills in Kubernetes, AWS, GitOps, security, and observability.

**Key Skills Demonstrated**:
- ✅ Infrastructure as Code (Terraform)
- ✅ Kubernetes orchestration (EKS, Helm)
- ✅ GitOps (Argo CD)
- ✅ CI/CD automation (GitHub Actions)
- ✅ Security best practices (IRSA, ESO, Kyverno)
- ✅ Observability (Prometheus, Grafana, Loki, Tempo)
- ✅ Multi-environment management
- ✅ Production operations

**Time Investment**: This represents a complete platform migration from legacy to cloud-native, demonstrating end-to-end DevOps capabilities.

**Production Readiness**: ✅ All critical components are production-ready and security-hardened.

---

## 🎯 Project Overview

**What it does**: A complete DevOps platform for deploying and managing banking microservices across dev, staging, and production environments on AWS EKS.

**Key Achievement**: Migrated from local Docker Compose to a production-grade, multi-environment Kubernetes platform with:
- **3 separate EKS clusters** (dev/staging/prod) with isolated infrastructure
- **4 microservices** (accounts, cards, loans, gateway) deployed via GitOps
- **Full CI/CD automation** with security scanning, image signing, and artifact management
- **Zero-trust security** with IRSA, network policies, and policy-as-code
- **Complete observability** with Prometheus, Grafana, Loki, and Tempo

---

## 📊 Project Status

| Component | Status | Notes |
|-----------|--------|-------|
| Infrastructure | ✅ Production Ready | All environments provisioned |
| Security | ✅ Hardened | IRSA, ESO, Kyverno, network policies |
| CI/CD | ✅ Automated | Full pipeline with scanning & signing |
| Observability | ✅ Configured | Prometheus, Grafana, Loki, Tempo |
| GitOps | ✅ Operational | Argo CD with automated sync |
| Alerting | ⚠️ Partial | Alertmanager configured, notifications pending |

---

## 📊 Platform Metrics

- **Environments**: 3 (dev, staging, production)
- **EKS Clusters**: 3 (one per environment)
- **Microservices**: 4 (accounts, cards, loans, gateway)
- **Infrastructure Modules**: 8 reusable Terraform modules
- **Helm Charts**: 7 (4 services + 3 environments)
- **Argo CD Applications**: 30+ (apps, monitoring, policies per environment)
- **Security Policies**: Kyverno policies enforcing network isolation
- **Observability**: Full stack (metrics, logs, traces)

---

## 🏗️ Architecture

### High-Level Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                    GitHub Repository                          │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐    │
│  │   Terraform  │  │  Helm Charts │  │  GitOps Manifests │    │
│  │   (IaC)      │  │  (K8s Apps)  │  │  (Argo CD)        │    │
│  └──────┬───────┘  └───────┬──────┘  └────────┬──────────┘    | 
└─────────┼──────────────────┼──────────────────┼───────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Actions (CI/CD)                         │  
│  • Build & Test • Trivy Scan • Cosign Sign • ECR Push       │
└───────────────────────────┬─────────────────────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                 ▼
    ┌──────────┐      ┌──────────┐      ┌──────────┐
    │   DEV    │      │  STAGING │      │   PROD   │
    │  EKS     │      │   EKS    │      │   EKS    │
    └──────────┘      └──────────┘      └──────────┘
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                 ▼
    ┌──────────┐      ┌──────────┐      ┌──────────┐
    │ Argo CD  │      │ Argo CD  │      │ Argo CD  │
    │ (GitOps) │      │ (GitOps) │      │ (GitOps) │
    └──────────┘      └──────────┘      └──────────┘
                            │
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                 ▼
    ┌──────────┐      ┌──────────┐      ┌──────────┐
    │Services  │      │Services  │      │Services  │
    │+Monitoring│     │+Monitoring│     │+Monitoring│
    └──────────┘      └──────────┘      └──────────┘
```

### Architecture Transformation

| Aspect | Before (Legacy) | After (Cloud-Native) |
|--------|----------------|---------------------|
| **Deployment** | Single host, Docker Compose | Multi-environment EKS clusters |
| **Infrastructure** | Manual setup | Terraform IaC with remote state |
| **Deployment Method** | Manual `docker-compose up` | GitOps with Argo CD (automated sync) |
| **Secrets Management** | Hardcoded in config files | AWS Secrets Manager + External Secrets Operator |
| **Security** | Basic | IRSA, Network Policies, Kyverno, Cosign signing |
| **Observability** | Basic health checks | Prometheus + Grafana + Loki + Tempo |
| **CI/CD** | Manual builds | Automated with OIDC, scanning, signing |
| **Scaling** | Manual | HPA, ResourceQuota, PDBs |

**Architecture Diagram**: See [11-docs/diagrams/after-diagram.png](11-docs/diagrams/after-diagram.png)

---

## ✨ Key Features & Capabilities

### 🔒 Security-First Design
- **IRSA (IAM Roles for Service Accounts)**: Each service has scoped IAM role, no long-lived credentials
- **External Secrets Operator**: Secrets synced from AWS Secrets Manager, no secrets in Git
- **Kyverno Policy-as-Code**: Enforces network policies, security contexts, image signing
- **Cosign Image Signing**: All container images signed and verified before deployment
- **Network Policies**: Zero-trust networking, explicit ingress/egress rules
- **Least-Privilege IAM**: GitHub Actions uses OIDC, ECR access restricted to specific repos
- **Security Scanning**: Trivy (containers), Checkov/tfsec (IaC) in CI/CD pipeline

### 🚀 GitOps & Automation
- **Argo CD App-of-Apps Pattern**: Centralized management of all applications
- **Automated Sync**: Self-healing, drift detection, automated reconciliation
- **Production Sync Windows**: Prevents deployments during business hours
- **Multi-Environment Management**: Separate Argo CD projects with RBAC

### 📊 Observability Stack
- **Prometheus**: Metrics collection with custom alerting rules
- **Grafana**: Pre-configured dashboards for services and infrastructure
- **Loki**: Centralized log aggregation with S3 backend
- **Tempo**: Distributed tracing with OpenTelemetry instrumentation
- **Alertmanager**: Configured with routing and receivers (ready for SMTP/Slack)

### 🏭 Infrastructure as Code
- **Terraform Modules**: Reusable, modular IaC for VPC, EKS, RDS, ECR, IAM
- **Remote State**: S3 backend with DynamoDB locking per environment
- **Multi-Environment**: Dev, staging, production with environment-specific configs
- **Validation**: Automated Terraform validation, Checkov, and tfsec scanning

### 🔄 CI/CD Pipeline
- **OIDC Authentication**: No AWS access keys, uses GitHub OIDC provider
- **Multi-Stage Builds**: Test → Scan → Sign → Push → Deploy
- **Security Scanning**: Trivy filesystem and image scanning, SBOM generation
- **Artifact Management**: All artifacts (scans, SBOMs, plans) archived to S3
- **Helm Linting**: Automated chart validation with dependency building

### 📦 Kubernetes Best Practices
- **Service-per-Chart Architecture**: Each microservice has dedicated Helm chart
- **Shared Templates**: DRY principle with `bankingapp-common` library chart
- **Resource Management**: ResourceQuota, LimitRange, PodDisruptionBudgets
- **Horizontal Pod Autoscaling**: CPU/memory-based autoscaling configured
- **Health Checks**: Liveness and readiness probes with proper timeouts

---

## 🛠️ Technology Stack

### Infrastructure & Orchestration
- **Kubernetes**: EKS 1.28+ (3 clusters: dev, staging, production)
- **Container Runtime**: Docker
- **Container Registry**: AWS ECR
- **Load Balancing**: AWS Application Load Balancer (ALB) via ALB Ingress Controller

### Infrastructure as Code
- **Terraform**: 1.6.0+ (modular architecture, remote state)
- **Helm**: 3.13.0+ (service-per-chart pattern)

### GitOps & Deployment
- **Argo CD**: Latest (app-of-apps pattern, automated sync)
- **Argo CD Image Updater**: Automated image updates with semver strategies

### CI/CD
- **GitHub Actions**: OIDC-based authentication
- **Trivy**: Container and filesystem vulnerability scanning
- **Cosign**: Container image signing and verification
- **Checkov**: Terraform security scanning
- **tfsec**: Terraform security analysis

### Security
- **External Secrets Operator**: AWS Secrets Manager integration
- **Kyverno**: Policy-as-code enforcement
- **IRSA**: IAM Roles for Service Accounts
- **Network Policies**: Kubernetes network isolation

### Observability
- **Prometheus Operator**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation (S3 backend)
- **Tempo**: Distributed tracing
- **OpenTelemetry**: Instrumentation for Java services

### Application Stack
- **Java**: Spring Boot microservices
- **Database**: PostgreSQL (RDS)
- **API Gateway**: Spring Cloud Gateway

---

## 📁 Project Structure

```
Multi-Environment-Microservices/
├── 05-terraform/                 # Infrastructure as Code
│   ├── environments/            # Environment-specific configs
│   │   ├── dev/                 # Dev environment
│   │   ├── stag/                # Staging environment
│   │   └── prod/                # Production environment
│   └── modules/                 # Reusable Terraform modules
│       ├── vpc/                 # VPC, subnets, security groups
│       ├── eks/                 # EKS cluster and node groups
│       ├── rds/                 # PostgreSQL database
│       ├── ecr/                 # Container registries
│       └── iam/                 # IAM roles (IRSA, OIDC, etc.)
│
├── 06-helm/                     # Kubernetes application charts
│   ├── bankingapp-common/       # Shared templates library
│   ├── bankingapp-services/     # Service-specific charts
│   │   ├── accounts/
│   │   ├── cards/
│   │   ├── loans/
│   │   └── gateway/
│   └── environments/           # Environment app-of-apps charts
│       ├── dev-env/
│       ├── stag-env/
│       └── prod-env/
│
├── 07-gitops/                   # Argo CD application manifests
│   ├── dev/applications/        # Dev Argo CD apps
│   ├── stag/applications/       # Staging Argo CD apps
│   └── prod/applications/       # Production Argo CD apps
│
├── 08-monitoring/               # Observability stack
│   ├── prometheus-operator/     # Prometheus & Alertmanager
│   │   ├── alerts/              # PrometheusRule resources
│   │   └── values/              # Environment-specific values
│   ├── loki/                    # Log aggregation
│   ├── tempo/                   # Distributed tracing
│   ├── grafana/                 # Dashboards
│   └── resources/               # ResourceQuota & LimitRange
│
├── .github/workflows/           # CI/CD pipelines
│   ├── Microservice-Ci.yaml     # Service build & deploy
│   ├── terraform-validate.yaml  # Terraform validation
│   ├── terraform-plan.yaml      # Terraform planning
│   ├── terraform-apply.yaml     # Terraform apply
│   └── helm-lint.yaml           # Helm chart linting
│
├── 10-security/                 # Security documentation
├── 11-docs/                     # Additional documentation
│   ├── runbooks/                # Operational procedures
│   └── diagrams/                # Architecture diagrams
│
└── 01-accounts/ 02-cards/ 03-loans/ 04-gatewayserver/  # Microservice source code
```

**Key Entry Points**:
- Infrastructure: `05-terraform/environments/{env}/main.tf`
- Applications: `06-helm/environments/{env}-env/values.yaml`
- GitOps: `07-gitops/{env}/applications/`

---

## 🚀 Deployment Flow

### 1. Infrastructure Provisioning
```bash
# Provision infrastructure for an environment
cd 05-terraform/environments/dev
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

**What gets created**:
- VPC with public/private subnets across 2 AZs
- EKS cluster with managed node groups
- RDS PostgreSQL instance in private subnet
- ECR repositories for each service
- IAM roles (IRSA, GitHub OIDC, ALB Controller, ESO)
- Kubernetes operators (Argo CD, ESO, Kyverno, ALB Controller)

### 2. GitOps Deployment (Automatic)
Once infrastructure is provisioned:
1. Argo CD is installed via Terraform (Helm release)
2. Argo CD syncs applications from `07-gitops/` directory
3. Applications deploy microservices, monitoring stack, and policies
4. External Secrets Operator syncs DB credentials from AWS Secrets Manager

### 3. CI/CD Pipeline (On Code Push)
```
Code Push → GitHub Actions → Build & Test → Trivy Scan → Cosign Sign → ECR Push → Argo CD Sync
```

**Pipeline stages**:
1. **Lint & Test**: Maven build, unit tests, code coverage
2. **Security Scan**: Trivy filesystem and image scanning
3. **Sign & Push**: Cosign signing, SBOM generation, ECR push
4. **Artifact Archive**: Upload scans, SBOMs, test reports to S3
5. **GitOps Sync**: Argo CD detects new image and syncs (if auto-sync enabled)

---

## 🔐 Security Posture

### IAM & Authentication
- ✅ **IRSA**: Each service has dedicated IAM role, no AWS credentials in pods
- ✅ **GitHub OIDC**: CI/CD uses OIDC, no long-lived AWS access keys
- ✅ **Least Privilege**: ECR access restricted to specific repositories
- ✅ **Service Accounts**: Properly annotated with IRSA role ARNs

### Secrets Management
- ✅ **AWS Secrets Manager**: RDS credentials stored securely
- ✅ **External Secrets Operator**: Automatic sync to Kubernetes secrets
- ✅ **No Secrets in Git**: All sensitive data in AWS Secrets Manager
- ✅ **.gitignore**: Excludes `.tfvars` files (contains account IDs)

### Container Security
- ✅ **Image Signing**: Cosign signs all images, Kyverno verifies signatures
- ✅ **Vulnerability Scanning**: Trivy scans in CI/CD pipeline
- ✅ **Security Contexts**: Enforced via Helm templates and Kyverno
- ✅ **Non-Root Containers**: All containers run as non-root user

### Network Security
- ✅ **Network Policies**: Zero-trust networking, explicit ingress/egress
- ✅ **Private Subnets**: RDS and EKS nodes in private subnets
- ✅ **Security Groups**: Restrictive rules for EKS and RDS

### Policy Enforcement
- ✅ **Kyverno**: Enforces network policies, security contexts, image signing
- ✅ **IaC Scanning**: Checkov and tfsec scan Terraform code
- ✅ **Deletion Protection**: Enabled for production and staging RDS

---

## 📊 Observability

### Metrics (Prometheus)
- **Application Metrics**: Spring Boot Actuator endpoints (`/actuator/prometheus`)
- **Kubernetes Metrics**: Node, pod, container metrics via kube-state-metrics
- **Custom Alerts**: Pod crashes, high CPU/memory, HTTP errors, Argo CD sync failures

### Logs (Loki)
- **Centralized Logging**: All pod logs aggregated in Loki
- **S3 Backend**: Logs stored in S3 for long-term retention
- **Grafana Integration**: Logs queryable from Grafana dashboards

### Traces (Tempo)
- **Distributed Tracing**: OpenTelemetry instrumentation for Java services
- **Trace Correlation**: Links traces to logs in Grafana

### Dashboards (Grafana)
- **Application Overview**: Service health, request rates, error rates
- **Kubernetes Pods**: Resource usage, pod status
- **JVM Metrics**: Memory, GC, thread pools
- **HTTP Request Metrics**: Latency, throughput, status codes

**Access**: Grafana available via port-forward (see [08-monitoring/README.md](08-monitoring/README.md))

---

## 🎓 Key Design Decisions

### Why Service-per-Chart?
- **Isolation**: Each service can be versioned and deployed independently
- **Flexibility**: Service-specific configurations without affecting others
- **Scalability**: Easy to add new services without modifying existing charts

### Why App-of-Apps Pattern?
- **Centralized Management**: All applications managed from one place
- **Consistency**: Same sync policies and configurations across environments
- **Scalability**: Easy to add new applications without manual Argo CD setup

### Why IRSA Instead of Access Keys?
- **Security**: No long-lived credentials, automatic credential rotation
- **Auditability**: CloudTrail logs show which service account accessed which resource
- **Least Privilege**: Each service gets only the permissions it needs

### Why External Secrets Operator?
- **GitOps Compliance**: Secrets managed outside Git, synced automatically
- **Centralized Management**: All secrets in AWS Secrets Manager
- **Automatic Rotation**: ESO can sync updated secrets without pod restarts

### Why Multi-Environment Terraform?
- **Isolation**: Separate state files prevent cross-environment drift
- **Flexibility**: Different configurations per environment (instance sizes, node counts)
- **Safety**: Production changes don't affect dev/staging

---

## ✅ Production-Ready Features

### Infrastructure
- ✅ Multi-AZ deployment for high availability
- ✅ Deletion protection on production databases
- ✅ Remote state with DynamoDB locking
- ✅ Environment isolation (separate clusters)

### Security
- ✅ Zero-trust networking (Network Policies)
- ✅ No secrets in Git (AWS Secrets Manager + ESO)
- ✅ Image signing and verification (Cosign + Kyverno)
- ✅ Least-privilege IAM (IRSA, OIDC)

### Reliability
- ✅ PodDisruptionBudgets for graceful shutdowns
- ✅ ResourceQuota and LimitRange for resource management
- ✅ Horizontal Pod Autoscaling
- ✅ Health checks (liveness & readiness probes)

### Observability
- ✅ Comprehensive alerting rules
- ✅ Centralized logging with S3 backend
- ✅ Distributed tracing
- ✅ Pre-configured Grafana dashboards

---

## 📚 Documentation

### Component Documentation
- **[Terraform](05-terraform/README.md)**: Infrastructure provisioning, modules, remote state
- **[Helm](06-helm/README.md)**: Chart structure, service deployment, environment configs
- **[GitOps](07-gitops/README.md)**: Argo CD setup, app-of-apps pattern, sync policies
- **[CI/CD](.github/workflows/README.md)**: GitHub Actions workflows, OIDC, security scanning
- **[Monitoring](08-monitoring/README.md)**: Prometheus, Grafana, Loki, Tempo setup
- **[Security](10-security/README.md)**: ESO, Kyverno, IRSA, network policies, image signing

### Operational Runbooks
- **[Scaling Services](11-docs/runbooks/scaling-services.md)**: Horizontal and vertical scaling
- **[Troubleshooting Pod Crashes](11-docs/runbooks/troubleshooting-pod-crashes.md)**: Debug pod failures
- **[Argo CD Sync Failures](11-docs/runbooks/argocd-sync-failures.md)**: Resolve sync issues
- **[Security Incident Response](11-docs/runbooks/security-incident-response.md)**: Security procedures
- **[Database Backup & Restore](11-docs/runbooks/database-backup-restore.md)**: RDS operations

---

## 🚦 Quick Start

### Prerequisites
```bash
# Verify tools are installed
terraform version  # Should be >= 1.6.0
helm version        # Should be >= 3.13.0
kubectl version    # Should be >= 1.28.0
aws --version      # AWS CLI configured
```

### Step-by-Step Setup

#### 1. Clone and Explore
```bash
git clone https://github.com/YonatanDas/Banking-Microservices-Platform.git
cd Multi-Environment-Microservices
```

#### 2. Review Configuration
```bash
# Check environment variables needed
cat 05-terraform/environments/dev/dev.tfvars.example

# Review infrastructure modules
ls 05-terraform/modules/
```

#### 3. Provision Dev Environment
```bash
cd 05-terraform/environments/dev
terraform init
terraform plan -var-file=dev.tfvars
# Review output, then:
terraform apply -var-file=dev.tfvars
```

**Expected Output**: EKS cluster, VPC, RDS, ECR repos, IAM roles created

#### 4. Access the Cluster
```bash
# Configure kubectl
aws eks update-kubeconfig --name bankingapp-dev-eks --region us-east-1

# Verify
kubectl get nodes  # Should show 3 nodes
kubectl get namespaces  # Should show argocd, monitoring, default
```

#### 5. Access Argo CD
```bash
# Port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Open browser: https://localhost:8080
# Login: admin / <password-from-above>
```

**Expected**: You should see Argo CD applications syncing automatically

#### 6. Verify Deployments
```bash
# Check microservices
kubectl get pods -n default
# Expected: accounts, cards, loans, gateway pods running

# Check monitoring
kubectl get pods -n monitoring
# Expected: Prometheus, Grafana, Loki, Tempo pods running

# Check Argo CD apps
kubectl get applications -n argocd
# Expected: Multiple applications in Synced/Healthy state
```

**Troubleshooting**: See [11-docs/runbooks/](11-docs/runbooks/) for common issues

---

## 🧪 Testing & Validation

### CI/CD Pipeline Tests
- ✅ **Unit Tests**: Maven test execution with coverage reports
- ✅ **Helm Lint**: Chart validation with dependency building
- ✅ **Terraform Validate**: Syntax and configuration validation
- ✅ **Security Scanning**: Trivy (containers), Checkov/tfsec (IaC)

### Manual Validation
```bash
# Test Terraform configuration
terraform validate

# Test Helm charts
helm lint 06-helm/environments/dev-env
helm template 06-helm/environments/dev-env --debug

# Test Kubernetes manifests
kubectl apply --dry-run=client -f 08-monitoring/resources/
```

---

## 📈 Production Readiness Checklist

- ✅ **Infrastructure**: Multi-environment, isolated, deletion protection enabled
- ✅ **Security**: IRSA, ESO, Kyverno, network policies, image signing
- ✅ **Observability**: Prometheus, Grafana, Loki, Tempo configured
- ✅ **CI/CD**: Automated builds, scans, signing, deployments
- ✅ **GitOps**: Argo CD with automated sync, self-healing
- ✅ **Resource Management**: ResourceQuota, LimitRange, PDBs configured
- ✅ **High Availability**: Multi-AZ deployment, PDBs, HPA
- ⚠️ **Alertmanager**: Configured but notifications need SMTP/Slack setup
- ⚠️ **Integration Tests**: Recommended for production (not yet implemented)

---

## 🤝 Contributing

This is a portfolio/demonstration project. For questions or feedback:
- Review the component-specific READMEs in each directory
- Check operational runbooks in `11-docs/runbooks/`
- Examine architecture diagrams in `11-docs/diagrams/`

---




---

## 🏆 Project Highlights (For Recruiters)

**Scale & Complexity**:
- 3 production-grade EKS clusters
- 4 microservices with full CI/CD
- Complete observability stack
- Multi-environment infrastructure

**Technologies Mastered**:
- Kubernetes, EKS, Helm, Argo CD
- Terraform, AWS (EKS, RDS, ECR, IAM, Secrets Manager)
- Prometheus, Grafana, Loki, Tempo
- GitHub Actions, OIDC, Cosign, Trivy
- Security: IRSA, ESO, Kyverno, Network Policies

**Key Achievements**:
- Migrated legacy app to cloud-native architecture
- Implemented GitOps with Argo CD
- Established security-first practices
- Built complete observability stack
- Automated entire CI/CD pipeline

**Production Readiness**: ✅ All critical components production-ready, security hardened, monitoring configured.
