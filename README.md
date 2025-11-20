# Multi-Environment Banking Platform

[![Microservices CI](https://github.com/OWNER/Multi-Environment-Microservices/actions/workflows/Microservice-Ci.yaml/badge.svg?branch=main)](https://github.com/OWNER/Multi-Environment-Microservices/actions/workflows/Microservice-Ci.yaml)
[![Terraform Validate](https://github.com/OWNER/Multi-Environment-Microservices/actions/workflows/terraform-validate.yaml/badge.svg?branch=main)](https://github.com/OWNER/Multi-Environment-Microservices/actions/workflows/terraform-validate.yaml)
![IaC Security](https://img.shields.io/badge/IaC%20Security-Checkov%20%2B%20tfsec-success)
![Container Security](https://img.shields.io/badge/Containers-Trivy%20%2B%20Cosign-blue)
![Images](https://img.shields.io/badge/Images-AWS%20ECR%20(versioned)-informational)

## Executive Summary

This repository shows the end-to-end modernization of a Spring Boot banking application from a Docker Compose lab into a production-grade, multi-environment platform. Terraform now provisions VPC, EKS, ALB, RDS, Secrets Manager, Argo CD, and per-service IRSA roles on AWS. Helm charts encapsulate Kubernetes policies (HPAs, NetworkPolicies, ConfigMaps, ExternalSecrets) for each microservice, while GitHub Actions deliver DevSecOps automation (tests, Trivy, Cosign, SBOMs, Terraform security gates) and push signed images to ECR before Argo CD performs GitOps syncs into EKS.

## Before vs. After

| Capability | Legacy Stack | Modernized Stack |
| --- | --- | --- |
| Deployment | Single Docker Compose file on laptops | Terraform-managed AWS infra + Argo CD GitOps |
| Service discovery & config | Eureka + Config Server + Feign | Native K8s DNS, ConfigMaps, External Secrets, lighter code |
| Datastore | Local JDBC/Postgres creds in configs | Amazon RDS in private subnets, credentials in AWS Secrets Manager |
| Networking | Flat network, no ingress, no policies | ALB Ingress Controller, per-service NetworkPolicies, zero egress |
| CI/CD | Manual Maven builds | GitHub Actions (lint/test, Trivy FS & image scans, Cosign signing, SBOM, artifact archival) |
| IaC & Governance | Hand-built infra | Terraform modules + remote state + Checkov/tfsec + manual approval gates |
| Security | Plain-text secrets, no signing | IRSA + External Secrets Operator, Cosign signing, GitHub OIDC, S3 artifact trails |
| Scalability | Static containers | HPAs (2–6 pods, CPU/Mem @70%), ALB target-type ip, EKS managed nodes |

## Cloud Architecture

```mermaid
flowchart LR
  subgraph CICD["GitHub Actions"]
    CI[Microservices CI]
    TF[Terraform Workflows]
  end
  subgraph AWS["AWS Account"]
    IAM[(IAM OIDC Roles)]
    VPC[VPC + public/private subnets]
    EKS[EKS Control Plane]
    NG[Managed Node Groups]
    ALB[AWS Load Balancer Controller]
    RDS[(Amazon RDS Postgres)]
    SM[AWS Secrets Manager]
    ECR[ECR repos per service]
    Argo[Argo CD]
    ESO[External Secrets Operator]
  end
  CI -->|push images| ECR
  CI -->|assume role| IAM
  TF -->|OIDC| IAM
  IAM --> TF
  TF --> VPC & EKS & NG & ALB & RDS & SM & Argo & ESO
  Argo -->|sync Helm env charts| EKS
  ESO -->|inject secrets| EKS
  ECR -->|pull images| NG
  ALB -->|HTTP 80| Gateway
  Gateway --> Accounts & Cards & Loans
  RDS -->|JDBC| Accounts & Cards & Loans
```

## Kubernetes Architecture

```mermaid
flowchart TD
  ALB[ALB Ingress] --> Gtw[Gateway Server 8072]
  Gtw --> Acc[Accounts 8080]
  Gtw --> Crd[Cards 9000]
  Gtw --> Lon[Loans 8090]
  Cfg[ConfigMap + OTEL placeholders] --> Acc & Crd & Lon
  ESO[(ExternalSecret dev-db-credentials)] --> Sec[K8s Secret]
  Sec --> Acc & Crd & Lon
  HPA1[HPA 2-6 pods<br/>cpu/mem 70%] --> Acc
  HPA2 --> Crd
  HPA3 --> Lon
  Netpol[NetworkPolicies<br/>gateway-only ingress,<br/>egress DNS+443] --> Acc & Crd & Lon
  Obs[Actuator /metrics /health] --> PromStack[(Prom/Grafana collector)]
```

## Repository & Folder Map

```text
Multi-Environment-Microservices/
├─ accounts | cards | loans | gatewayserver      # Spring Boot services (8080/9000/8090/8072)
├─ helm/
│  ├─ bankingapp-common/                         # Shared Helm templates (Deployment, SA, HPA, NetworkPolicy)
│  ├─ bankingapp-services/<service>/             # Service-specific values + ingress/HPA overrides
│  └─ environments/{dev,stag,prod}-env/          # App-of-app Helm chart consumed by Argo CD
├─ terraform/
│  ├─ environments/{dev,stag,prod}/              # Remote-state stacks (S3 + DynamoDB locking)
│  └─ modules/{vpc,eks,ecr,rds,secrets,iam}/     # Reusable AWS building blocks incl. ALB ctrl & Argo CD
├─ .github/
│  ├─ workflows/                                 # Microservice CI + Terraform (validate/plan/apply)
│  ├─ scripts/                                   # Maven, Trivy, Cosign, Terraform helpers
│  └─ actions/                                   # Composite actions (AWS OIDC, caching, terraform setup)
└─ docker-compose.yaml                           # Legacy reference for local smoke testing
```

## CI/CD & DevSecOps Flow

- **Microservices pipeline (`.github/workflows/Microservice-Ci.yaml`):** dorny path-filter chooses changed services, runs Maven lint/tests, executes Trivy FS scans, builds multi-arch images with Buildx, pushes to ECR using GitHub OIDC, performs Trivy image + SBOM scans, Cosign signs and verifies images, and uploads every artifact (tests, scans, SBOM, build metadata) to S3.
- **Terraform guardrails:** `terraform-validate` workflow enforces `terraform fmt`, multi-env `terraform validate`, and parallel Checkov + tfsec scans before artifacts are archived. `terraform-plan` produces per-environment binary/text/JSON plans and stores them for manual review. `terraform-apply` reuses signed plans, enforces branch protections, and tags prod deployments.
- **Observability hooks:** every Spring service exposes `/actuator/health/*` and `/actuator/prometheus`, so probes + Prometheus scrapers can reuse the same endpoints. OTEL exporters are parameterized in `helm/environments/*/values.yaml`.
- **Artifact integrity:** GitHub Actions writes SBOMs, Trivy reports, Terraform plans, and apply logs to S3 (`my-ci-artifacts55`) for auditability.

## IRSA + External Secrets Flow

```mermaid
sequenceDiagram
  participant Pod as Spring Pod
  participant SA as ServiceAccount (accounts-sa/cards-sa/loans-sa)
  participant OIDC as EKS OIDC Provider
  participant IAM as IAM Role (dev-*-rds-access-role)
  participant ESO as External Secrets Operator
  participant ASM as AWS Secrets Manager (dev-db-credentials)
  participant K8sSecret as Kubernetes Secret
  Pod->>SA: needs DB_USER/DB_PASSWORD/HOST/DB_NAME
  SA->>OIDC: present signed service account token
  OIDC->>IAM: sts:AssumeRoleWithWebIdentity
  IAM-->>ESO: scoped temp creds (GetSecretValue)
  ESO->>ASM: fetch dev-db-credentials JSON
  ASM-->>ESO: username/password/dbhost/dbname
  ESO->>K8sSecret: render Kubernetes Secret
  K8sSecret-->>Pod: envFrom injection at deploy time
```

## Zero-Trust NetworkPolicy Model

```mermaid
graph LR
  GW[gateway 8072] --> AC[accounts 8080]
  GW --> CA[cards 9000]
  GW --> LO[loans 8090]
  AC <-->|allow| CA
  AC <-->|allow| LO
  CA <-->|allow| LO
  INTERNET((Internet)) -.blocked.-> AC
  INTERNET -.blocked.-> CA
  INTERNET -.blocked.-> LO
  DNS[CoreDNS + ESO webhooks] --> AC
  DNS --> CA
  DNS --> LO
```

NetworkPolicies are generated from `helm/bankingapp-common/templates/_networkpolicy.tpl` and limit ingress to gateway + explicit peers, while egress is constrained to sibling services plus UDP 53/TCP 443 for DNS and AWS APIs (External Secrets). This enforces pod-to-pod isolation and parity with zero-trust expectations.

## GitOps Deployment Workflow

1. Helm environment charts (`helm/environments/dev-env`, etc.) reference the packaged service charts and template shared ConfigMaps, ExternalSecrets, and SecretStores.
2. Terraform installs Argo CD (`helm_release.argocd`) and the AWS Load Balancer + External Secrets operators inside EKS.
3. Argo CD monitors this repository, syncs the environment chart per namespace, and continuously reconciles Deployments, Services, HPAs, NetworkPolicies, and ExternalSecrets.
4. GitHub Actions push new container tags (`v1.0.0`, `latest`) to ECR; Argo CD picks up the image tag bump committed to Git, guaranteeing Git-driven rollouts and instant rollbacks.

## Deployment Guide

1. **Prerequisites:** AWS CLI v2, kubectl, helm, Terraform ≥1.6, Cosign, and access to an AWS account with permissions to create EKS/RDS/VPC resources. Configure an S3 bucket and DynamoDB table (see `terraform/environments/*/backend.tf`).
2. **Clone & bootstrap:** `git clone` this repo, create a GitHub OIDC role (module `iam/github_oidc` does this), and populate required secrets (`AWS_ACCOUNT_ID`, `AWS_REGION`, artifact bucket) in GitHub.
3. **Customize environment vars:** edit `terraform/environments/<env>/variables.tf` & `*.tfvars` for CIDRs, instance sizes, and DB settings. Adjust Helm overrides in `helm/environments/<env>-env/values.yaml` for replica counts, ingress hostnames, and service account annotations.
4. **Plan infrastructure:** run `terraform -chdir=terraform/environments/dev init` followed by `terraform plan -var-file=dev.tfvars`. Alternatively trigger the `Terraform Plan` GitHub workflow with the target environment.
5. **Apply infrastructure:** approve the plan via `terraform-apply` workflow (dev auto-approve optional; staging/prod require uploaded plan artifacts). Terraform provisions VPC, EKS, node groups, ALB controller, External Secrets Operator, RDS, Secrets Manager, ECR repos, IRSA roles, and Argo CD.
6. **Build & publish services:** push to `main` to trigger `CI for Microservices`. The workflow builds all changed services, scans/signs images, and pushes to `063630846340.dkr.ecr.us-east-1.amazonaws.com/<service>:<tag>`.
7. **Sync Kubernetes via GitOps:** update the Helm image tag in `helm/bankingapp-services/<service>/values.yaml` (or environment overrides) and let Argo CD detect/roll out the revision. Verify via `kubectl get pods,ingress,hpa,networkpolicy`.
8. **Smoke test:** hit the ALB DNS on port 80 → `gatewayserver` (8072) → `/api/{accounts,cards,loans}`. Use `/actuator/health` and `/actuator/prometheus` for liveness and metrics validation.

## Recruiter Lens

- Demonstrates owning a full greenfield migration: requirements gathering, IaC modularization, Terraform governance, Kubernetes manifest engineering, and GitOps operations.
- Shows deep security focus: IRSA, External Secrets Operator, Trivy, Cosign, Checkov, tfsec, S3 audit trails, zero-trust networking, and branch-protected Terraform applies.
- Highlights scalability & reliability practices: HPAs, ALB target-type ip, readiness/liveness probes, environment-specific Helm overlays, and Observable Spring Actuator endpoints.
- Proves CI/CD maturity: multi-stage GitHub Actions with caching, matrix builds, artifact promotion, and manual approval steps for infra.

## Skills Demonstrated

- **Cloud & IaC:** AWS VPC/EKS/RDS/ECR/Secrets Manager, Terraform modules with remote state + locking, Helm-based GitOps, Argo CD operations.
- **Kubernetes:** Helm templating (shared chart + per-service overrides), External Secrets Operator, ALB ingress, NetworkPolicies, HPAs, ConfigMaps, service account annotations.
- **DevSecOps:** GitHub Actions, custom composite actions, Trivy FS/image scans, Cosign signing, SBOM generation, Checkov/tfsec security gates, artifact retention in S3.
- **Security & Networking:** IRSA, AWS OIDC federation, zero-trust pod communications, TLS termination via ALB, secret rotation via random_password + Secrets Manager.
- **Observability & Resilience:** Spring Actuator, Prometheus exposure, Resilience4j defaults, readiness/liveness probes, structured logging.

## Future Enhancements

- Automate canary or blue/green deployments via Argo Rollouts to complement the current Helm releases.
- Add managed Prometheus/Grafana or OpenTelemetry Collector and wire OTEL endpoints already parameterized in `helm/environments/*/templates/configmap.yaml`.
- Expand network policies to namespace isolation and integrate service mesh (e.g., AWS App Mesh or Istio) for mTLS.
- Implement automated database migrations (Flyway/Liquibase) inside the CI pipeline before rolling out services.
- Add chaos engineering hooks (Litmus, AWS FIS) to validate HPA + Resilience4j behavior under failure.

---

This README is intentionally concise yet comprehensive so a senior DevOps leader or hiring manager can quickly understand the modernization story, the current production-ready architecture, and the technical competencies proven by the implementation.

