# Multi-Environment Banking Platform

[![Microservices CI](https://github.com/YonatanDas/Banking-Microservices-Platform/actions/workflows/Microservice-Ci.yaml/badge.svg?branch=main)](https://github.com/YonatanDas/Banking-Microservices-Platform/actions/workflows/Microservice-Ci.yaml)
![Terraform](https://img.shields.io/badge/IaC-Terraform-844FBA?logo=terraform)
![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5?logo=kubernetes)
![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazonaws)
![Helm](https://img.shields.io/badge/Package_Manager-Helm-0F1689?logo=helm)
![GitOps](https://img.shields.io/badge/GitOps-ArgoCD-FF4F8B?logo=argo)

This project takes a **local Spring Boot microservices app** (running only via `docker-compose`) and transforms it into a **production-grade, cloud-native platform on AWS**.

It showcases **end-to-end DevOps skills**: Terraform IaC, AWS EKS, Helm, GitHub Actions CI/CD, GitOps with ArgoCD, IRSA-based secret management, ALB ingress, and zero-trust pod networking.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)  
2. [Before vs After Architecture](#2-before-vs-after-architecture)  
3. [Cloud Architecture Diagram](#3-cloud-architecture-diagram)  
4. [Kubernetes Architecture Diagram](#4-kubernetes-architecture-diagram)  
5. [Repository & Directory Structure](#5-repository--directory-structure)  
6. [CI/CD Flow](#6-cicd-flow)  
7. [IRSA Authentication Flow](#7-irsa-authentication-flow)  
8. [NetworkPolicy Model](#8-networkpolicy-model)  
9. [Deployment Workflow (GitOps + ArgoCD)](#9-deployment-workflow-gitops--argocd)  
10. [Setup & Deployment Guide](#10-setup--deployment-guide)  
11. [How Recruiters / Hiring Managers Should Read This Project](#11-how-recruiters--hiring-managers-should-read-this-project)  
12. [Skills Demonstrated](#12-skills-demonstrated)  
13. [Future Improvements](#13-future-improvements)  

---

## 1. Executive Summary

**Original state**

- Spring Boot microservices:
  - Accounts, Cards, Loans
  - Gateway (Spring Cloud Gateway)
  - Config Server, Eureka, Feign
- Deployed **only via Docker Compose** on a local machine
- **No** Kubernetes, no IaC, no CI/CD, no secret management, no GitOps, no autoscaling, no network security

**What this project does**

This project **redesigns and migrates** the system into a **cloud-native banking microservices platform on AWS**, featuring:

- **AWS EKS** cluster with **Terraform** (IaC)
- **ALB Ingress** for external access
- **AWS RDS** for persistent relational data
- **AWS ECR** for image registry
- **AWS Secrets Manager + IRSA + External Secrets** for secure secret delivery
- **GitHub Actions CI/CD** for app and infra
- **Helm charts per service** with HPA & NetworkPolicies
- **GitOps with ArgoCD** for declarative, automated sync to Kubernetes
- **Zero-trust networking** between pods using Kubernetes NetworkPolicies

**Why it matters**

This simulates how a real company would **modernize a legacy service into a secure, scalable, fully automated cloud platform**, and demonstrates end-to-end DevOps ownership.

---

## 2. Before vs After Architecture
    Before Architecture:
<img width="1596" height="1937" alt="image" src="https://github.com/user-attachments/assets/1a25784c-f114-44b1-92b2-a6387669354a" />

### 2.1 Legacy Architecture (Before)

- **Services**
  - Accounts, Cards, Loans, Gateway
  - Config Server (Spring Cloud Config)
  - Eureka (Service Discovery)
  - Feign Clients

- **Infrastructure**
  - Single machine, **docker-compose only**
  - Local JDBC database
  - No load balancer
  - No autoscaling

- **Operational gaps**
  - ❌ No Kubernetes  
  - ❌ No Terraform / IaC  
  - ❌ No CI/CD pipelines  
  - ❌ No cloud database (RDS)  
  - ❌ No secret management (passwords in configs)  
  - ❌ No GitOps  
  - ❌ No ingress controller  
  - ❌ No pod-to-pod security / NetworkPolicies  

### 2.2 Modern Cloud-Native Architecture (After)

- **AWS Infrastructure (via Terraform)**
  - VPC, subnets, route tables
  - EKS cluster + managed node groups
  - ALB Ingress Controller
  - ECR repositories
  - RDS instance
  - IAM OIDC provider + IRSA roles
  - Secrets Manager
  - ArgoCD

- **Application layer (Kubernetes + Helm)**
  - Microservices: `accounts`, `cards`, `loans`, `gateway`
  - Each deployed via **Helm chart**
  - HPA for autoscaling
  - NetworkPolicies for zero-trust traffic
  - ConfigMaps & ExternalSecrets for configuration and secrets

- **Delivery & Operations**
  - GitHub Actions CI/CD for:
    - Services (build, test, scan, build/push image, deploy via Helm)
    - Terraform (fmt, validate, lint, Checkov, plan, apply with approval)
  - GitOps with ArgoCD:
    - Watches Git for manifest changes
    - Syncs desired state to EKS automatically

### 2.3 Summary Comparison

| Aspect               | Before                               | After                                                     |
|----------------------|---------------------------------------|-----------------------------------------------------------|
| Deployment           | Local Docker Compose                  | AWS EKS (Terraform + Helm)                               |
| Infra Management     | Manual                                | Terraform IaC + GitHub Actions                           |
| Registry             | Local Docker                          | AWS ECR with versioned tags                              |
| Database             | Local JDBC                            | AWS RDS                                                  |
| Secrets              | In code / configs                     | AWS Secrets Manager + IRSA + External Secrets            |
| Service Discovery    | Eureka                                | Native Kubernetes DNS                                    |
| Config Mgmt          | Spring Config Server                  | ConfigMaps + ExternalSecrets                             |
| Networking           | Flat, no isolation                    | NetworkPolicies (zero-trust) + ALB Ingress               |
| Delivery             | Manual builds & deploys               | Automated CI/CD + GitOps (ArgoCD)                        |
| Autoscaling          | None                                  | Horizontal Pod Autoscaler (HPA)                          |

### 2.4 Capability Deep-Dive

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

---

## 3. Cloud Architecture Diagram

<img width="1848" height="2191" alt="image" src="https://github.com/user-attachments/assets/41e18c8d-a6a7-4ce7-8a64-4344c869783c" />


## 4. Kubernetes Architecture Diagram

<img width="2064" height="1535" alt="image" src="https://github.com/user-attachments/assets/e5e69c13-7533-491b-a494-8a4a8590df01" />


## 5. Repository & Directory Structure

```text
Banking-Microservices-Platform/
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

## 6. CI/CD Flow

- **Microservices pipeline (`.github/workflows/Microservice-Ci.yaml`):** dorny path-filter chooses changed services, runs Maven lint/tests, executes Trivy FS scans, builds multi-arch images with Buildx, pushes to ECR using GitHub OIDC, performs Trivy image + SBOM scans, Cosign signs and verifies images, and uploads every artifact (tests, scans, SBOM, build metadata) to S3.
<img width="2774" height="1725" alt="image" src="https://github.com/user-attachments/assets/95f52ad2-e40c-4f64-ae4d-c6e16c49c75f" />

- **Terraform guardrails:** `terraform-validate` workflow enforces `terraform fmt`, multi-env `terraform validate`, and parallel Checkov + tfsec scans before artifacts are archived. `terraform-plan` produces per-environment binary/text/JSON plans and stores them for manual review. `terraform-apply` reuses signed plans, enforces branch protections, and tags prod deployments.
<img width="2166" height="1684" alt="image" src="https://github.com/user-attachments/assets/b7cf60f8-7dfc-40fc-968f-07a12347083d" />

- **Observability hooks:** every Spring service exposes `/actuator/health/*` and `/actuator/prometheus`, so probes + Prometheus scrapers can reuse the same endpoints. OTEL exporters are parameterized in `helm/environments/*/values.yaml`.
- **Artifact integrity:** GitHub Actions writes SBOMs, Trivy reports, Terraform plans, and apply logs to S3 (`my-ci-artifacts55`) for auditability.
  <img width="2289" height="1256" alt="image" src="https://github.com/user-attachments/assets/ffdad273-a831-4be5-8b1c-4116df1e67c8" />


## 7. IRSA Authentication Flow

<img width="2064" height="1535" alt="image" src="https://github.com/user-attachments/assets/1dadeb65-1226-4940-9a80-08ec80f41d62" />


## 8. NetworkPolicy Model

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

## 9. Deployment Workflow (GitOps + ArgoCD)

1. Helm environment charts (`helm/environments/dev-env`, etc.) reference the packaged service charts and template shared ConfigMaps, ExternalSecrets, and SecretStores.
2. Terraform installs Argo CD (`helm_release.argocd`) and the AWS Load Balancer + External Secrets operators inside EKS.
3. Argo CD monitors this repository, syncs the environment chart per namespace, and continuously reconciles Deployments, Services, HPAs, NetworkPolicies, and ExternalSecrets.
4. GitHub Actions push new container tags (`v1.0.0`, `latest`) to ECR; Argo CD picks up the image tag bump committed to Git, guaranteeing Git-driven rollouts and instant rollbacks.

## 10. Setup & Deployment Guide

1. **Prerequisites:** AWS CLI v2, kubectl, helm, Terraform ≥1.6, Cosign, and access to an AWS account with permissions to create EKS/RDS/VPC resources. Configure an S3 bucket and DynamoDB table (see `terraform/environments/*/backend.tf`).
2. **Clone & bootstrap:** `git clone` this repo, create a GitHub OIDC role (module `iam/github_oidc` does this), and populate required secrets (`AWS_ACCOUNT_ID`, `AWS_REGION`, artifact bucket) in GitHub.
3. **Customize environment vars:** edit `terraform/environments/<env>/variables.tf` & `*.tfvars` for CIDRs, instance sizes, and DB settings. Adjust Helm overrides in `helm/environments/<env>-env/values.yaml` for replica counts, ingress hostnames, and service account annotations.
4. **Plan infrastructure:** run `terraform -chdir=terraform/environments/dev init` followed by `terraform plan -var-file=dev.tfvars`. Alternatively trigger the `Terraform Plan` GitHub workflow with the target environment.
5. **Apply infrastructure:** approve the plan via `terraform-apply` workflow (dev auto-approve optional; staging/prod require uploaded plan artifacts). Terraform provisions VPC, EKS, node groups, ALB controller, External Secrets Operator, RDS, Secrets Manager, ECR repos, IRSA roles, and Argo CD.
6. **Build & publish services:** push to `main` to trigger `CI for Microservices`. The workflow builds all changed services, scans/signs images, and pushes to `063630846340.dkr.ecr.us-east-1.amazonaws.com/<service>:<tag>`.
7. **Sync Kubernetes via GitOps:** update the Helm image tag in `helm/bankingapp-services/<service>/values.yaml` (or environment overrides) and let Argo CD detect/roll out the revision. Verify via `kubectl get pods,ingress,hpa,networkpolicy`.
8. **Smoke test:** hit the ALB DNS on port 80 → `gatewayserver` (8072) → `/api/{accounts,cards,loans}`. Use `/actuator/health` and `/actuator/prometheus` for liveness and metrics validation.

## 11. How Recruiters / Hiring Managers Should Read This Project

This project demonstrates the ability to:

- Take a legacy, non-cloud-ready system and deliver a full modernization roadmap plus execution.
- Implement Terraform-based AWS infrastructure from scratch (VPC, EKS, managed node groups, RDS, IAM/IRSA, ECR, ALB controller, Secrets Manager, Argo CD, External Secrets Operator).
- Design a secure, scalable Kubernetes deployment with service-per-chart Helm layout, centralized `bankingapp-common` templates, HPAs (2–6 pods, CPU/memory @70%), and NetworkPolicies for zero-trust communication.
- Operate dual CI/CD pipelines: Microservices delivery (build → test → scan → sign → push → SBOM) and Terraform delivery (fmt/validate → security checks → plan → approval → apply).
- Apply best-practice cloud security: IRSA workload identity, AWS Secrets Manager via External Secrets, NetworkPolicies restricting ingress/egress, GitHub OIDC federation, Cosign signature verification, and artifact archival in S3.
- Adopt GitOps (Argo CD) for declarative, auditable releases across `dev`, `stag`, and `prod` Helm environment charts.

In short, the repository reflects production-ready DevOps/Platform Engineering work that stands up an entire banking platform on AWS with automation, security, and observability wired in.

## 12. Skills Demonstrated

### 12.1 Cloud & AWS

- EKS cluster design & provisioning (`terraform/modules/eks`) with control-plane logging and managed node groups.
- VPC networking (public/private subnets, security groups, route tables in `terraform/modules/vpc`).
- RDS Postgres provisioning and secure connectivity through private subnets plus generated credentials (`terraform/modules/rds` + `modules/secrets`).
- ECR repositories per service with versioned tags; used by GitHub Actions Buildx jobs.
- IAM OIDC provider & IRSA roles for each service account (`terraform/modules/iam/*`).
- ALB Ingress Controller installation via Helm release, exposing the gateway service on HTTP 80.

### 12.2 Kubernetes & Helm

- Multi-service deployment with individual charts under `helm/bankingapp-services/*`.
- DRY shared templates in `helm/bankingapp-common` for Deployments, HPAs, NetworkPolicies, ServiceAccounts, and Services.
- HPAs defined per service (autoscaling/v2) to keep CPU/memory utilization near 70%.
- NetworkPolicies enforcing explicit ingress/egress matrices and DNS/443 exceptions only.
- ConfigMaps for shared runtime configuration plus ExternalSecret/SecretStore objects for secret injection.

### 12.3 Infra-as-Code (Terraform)

- Environment-based structure (`terraform/environments/{dev,stag,prod}`) with remote state (S3) and DynamoDB locking.
- Reusable modules for VPC, EKS, RDS, IAM, ECR, Secrets, ALB controller, External Secrets Operator, and Argo CD.
- Automated validation, linting, and security scanning (`terraform-validate` workflow uses fmt, validate, Checkov, tfsec, and custom scripts).
- Workflow-driven plans (`terraform-plan`) and manual approvals before applies, aligning with team change-control processes.

### 12.4 CI/CD & GitHub Actions

- Multi-stage microservices workflow: Maven lint/tests → Trivy FS scan → Buildx image build → ECR push → Trivy image scan + SBOM → Cosign sign/verify → artifact upload to S3.
- Separate Terraform workflows for validate, plan, and apply with environment inputs and approval gates.
- Manual approval (plan artifact review) required for Terraform apply; dev can opt into auto-approve while staging/prod require uploaded plans.
- Integrations with ECR, helm packaging, Argo CD GitOps, and S3 artifact archival for audit trails.

### 12.5 Security & Networking

- AWS Secrets Manager + External Secrets Operator eliminate plaintext credentials; IRSA ensures least-privilege access.
- Network segmentation via generated NetworkPolicies with per-service allowlists and restricted egress.
- ALB ingress configuration (gateway chart) with target-type `ip`, HTTP listener, and pod-level targeting.
- Continuous security scanning: Trivy FS/image, Checkov, tfsec, Cosign signatures, SBOM creation, and GitHub OIDC trust relationships.

### 12.6 GitOps & Release Engineering

- Argo CD installed via Terraform Helm release; monitors `helm/environments/*` charts.
- Declarative, versioned deployments (Helm values define image tags, replica counts, SA annotations).
- Automated sync, drift detection, and rollback via Git history; aligns with GitOps best practices.

## 13. Future Improvements

Intentional next steps to keep evolving the platform:

1. **Observability Stack**
   - Add Prometheus + Grafana (or Amazon Managed Prometheus/Grafana) to consume existing `/actuator/prometheus` endpoints.
   - Layer centralized logging (Loki or ELK) and define alert rules tied to SLOs.
2. **Progressive Delivery**
   - Introduce Argo Rollouts or Flagger for canary/blue-green strategies.
   - Use ALB annotations for traffic shifting during rollouts.
3. **Policy as Code**
   - Add OPA/Gatekeeper or Kyverno to enforce guardrails (no privileged pods, mandatory resource limits, etc.).
4. **More Environments**
   - Expand the current dev/stag/prod Helm + Terraform stacks into separate AWS accounts or workspaces for stronger isolation.
5. **Cost Optimization**
   - Right-size node groups and RDS instances; consider spot nodes for non-prod workloads.
6. **Advanced Security**
   - Integrate container scanning into the registry lifecycle, add AWS WAF in front of ALB, and enable mTLS between services (service mesh).
7. **Resilience & Automation**
   - Automate schema migrations (Flyway/Liquibase) within CI, and add chaos experiments (Litmus or AWS FIS) to validate resilience patterns.

---

This README is intentionally concise yet comprehensive so a senior DevOps leader or hiring manager can quickly understand the modernization story, the current production-ready architecture, and the technical competencies proven by the implementation.

