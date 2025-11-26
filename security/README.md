# Security Documentation

This project implements multiple layers of security controls: Infrastructure as Code (IaC) scanning, runtime policy enforcement, network segmentation, secrets management, image signing/verification, Software Bill of Materials (SBOM) generation, and least-privilege IAM. All security controls are automated and managed as code.

---

## External Secrets Operator (ESO)

![ESO architecture](docs\diagrams\ESO-diagram.png)


- **What it protects**: Eliminates hardcoded secrets in Kubernetes manifests and Helm values by pulling credentials from AWS Secrets Manager
- **Implementation**: Installed via Terraform (`terraform/modules/eks/external_secrets.tf`), uses IRSA role (`terraform/modules/iam/external_secrets_role`) with least-privilege Secrets Manager read access
- **How it works**: `ClusterSecretStore` authenticates via IRSA; `ExternalSecret` resources in `helm/environments/*-env/templates/externalsecret.yaml` sync DB credentials to Kubernetes Secrets
- **Why it matters**: Prevents secret leakage in Git, enables secret rotation without redeployment, enforces least-privilege access via IAM policies
- **Files**: `terraform/modules/iam/external_secrets_role/main.tf`, `helm/environments/*-env/templates/externalsecret.yaml`, `helm/environments/*-env/templates/secretstore.yaml`

---
## OIDC-based Access

- **What it protects**: Eliminates long-lived AWS credentials for CI/CD and Kubernetes service accounts
- **Implementation**: GitHub Actions uses OIDC provider (`terraform/modules/iam/github_oidc`) to assume `github-actions-eks-ecr-role`; Kubernetes service accounts use IRSA (EKS OIDC provider) to assume IAM roles for RDS/Secrets Manager access
- **How it works**: GitHub OIDC issues short-lived tokens scoped to repository/workflow; IRSA annotates ServiceAccounts with `eks.amazonaws.com/role-arn`, enabling pods to assume IAM roles via `sts:AssumeRoleWithWebIdentity`
- **Why it matters**: Reduces credential exposure risk, enables fine-grained access control, supports compliance requirements (no static secrets)
- **Files**: `terraform/modules/iam/github_oidc/main.tf`, `terraform/modules/iam/github_oidc/github_actions_role.tf`, `.github/actions/env-setup/action.yaml`, `helm/environments/*-env/values.yaml` (ServiceAccount annotations)

---

## Pod Network Policies

- **What it protects**: Enforces zero-trust networking between pods, blocking unauthorized ingress/egress traffic
- **Implementation**: NetworkPolicies generated from `helm/bankingapp-common/templates/_networkpolicy.tpl`; gateway allows ingress from ALB, microservices allow ingress only from gateway and explicit peer services
- **How it works**: Egress restricted to sibling services, DNS (UDP 53), and HTTPS (TCP 443) for External Secrets Operator; monitoring namespace allowed for Prometheus scraping and OTEL traces
- **Why it matters**: Limits blast radius of compromised pods, enforces defense-in-depth, aligns with zero-trust security model
- **Files**: `helm/bankingapp-common/templates/_networkpolicy.tpl`, `helm/bankingapp-common/templates/_denyAllIngress.tpl`, `helm/bankingapp-common/templates/_denyAllEgress.tpl`

---



## Kyverno Policies

- **What it protects**: Enforces security policies at Kubernetes admission time, blocking non-compliant workloads before deployment
- **Implementation**: Kyverno installed via Terraform (`terraform/modules/eks/kyverno.tf`); ClusterPolicies in `kyverno/policies/cluster/` deployed via Argo CD (`gitops/*/applications/kyverno-policies-*.yaml`)
- **How it works**: Policies validate images (Cosign signatures, semantic versions, ECR registry), enforce non-root users, require resource limits, block privileged containers, and audit NetworkPolicy presence
- **Why it matters**: Policy-as-code ensures consistent security posture, prevents misconfigurations, enables compliance automation (e.g., PCI-DSS, SOC 2)
- **Files**: `kyverno/policies/cluster/*.yaml` (9 policies: require-cosign-signature, require-semantic-version, restrict-ecr-registry, block-privileged-containers, enforce-non-root, require-resource-limits, require-network-policy, deny-empty-env-vars, deny-hostpath-mounts)

---

## Checkov (IaC Security Scanning)

- **What it protects**: Scans Terraform code for security misconfigurations, insecure defaults, and compliance violations before infrastructure deployment
- **Implementation**: Runs in `terraform-validate` GitHub Actions workflow (`.github/workflows/terraform-validate.yaml`) via script `.github/scripts/09-checkov-security-scan.sh`
- **How it works**: Scans all Terraform files in `terraform/` directory, checks against 1000+ policies (AWS, Kubernetes, general security), outputs SARIF format for GitHub Security tab
- **Why it matters**: Prevents insecure infrastructure at the source, enables shift-left security, supports compliance audits (SOC 2, CIS benchmarks)
- **Files**: `.github/workflows/terraform-validate.yaml`, `.github/scripts/09-checkov-security-scan.sh`

---

## Cosign (Image Signing & Verification)

- **What it protects**: Ensures container images are authentic and untampered, preventing supply chain attacks
- **Implementation**: Images signed with Cosign keyless signing in CI/CD (`.github/scripts/06-cosign-sign-verify.sh`); Kyverno policy `require-cosign-signature` verifies signatures at admission time
- **How it works**: GitHub Actions workflow signs images using OIDC certificate identity (`https://github.com/YonatanDas/Banking-Microservices-Platform/.github/workflows/Microservice-Ci.yaml@refs/heads/main`); Kyverno validates signature and certificate before allowing pod creation
- **Why it matters**: Prevents deployment of unsigned or tampered images, enables supply chain security compliance (SLSA, NIST), supports image provenance tracking
- **Files**: `.github/scripts/06-cosign-sign-verify.sh`, `kyverno/policies/cluster/require-cosign-signature.yaml`, `.github/workflows/Microservice-Ci.yaml`

---

## SBOM Generation (Software Bill of Materials)

- **What it protects**: Provides transparency into container image dependencies, enabling vulnerability tracking and license compliance
- **Implementation**: Trivy generates CycloneDX SBOMs in CI/CD (`.github/scripts/07-image-scan-sbom.sh`); SBOMs uploaded to S3 for auditability
- **How it works**: After image build, Trivy scans image layers, generates SBOM in CycloneDX JSON format, archives to S3 bucket `my-ci-artifacts55`
- **Why it matters**: Required for compliance (e.g., Executive Order 14028), enables dependency vulnerability tracking, supports license audits
- **Files**: `.github/scripts/07-image-scan-sbom.sh`, `.github/workflows/Microservice-Ci.yaml`

---

## Trivy Scanning

- **What it protects**: Identifies vulnerabilities in application code (filesystem scan) and container images (image scan) before deployment
- **Implementation**: Filesystem scan (`.github/scripts/02-trivy-fs-scan.sh`) runs before image build; image scan (`.github/scripts/07-image-scan-sbom.sh`) runs after image push to ECR
- **How it works**: Trivy scans for CVEs in dependencies (Maven, npm, etc.) and base images; outputs SARIF and JSON reports; fails build on HIGH/CRITICAL vulnerabilities (configurable)
- **Why it matters**: Prevents known vulnerabilities from reaching production, enables proactive patching, supports vulnerability management workflows
- **Files**: `.github/scripts/02-trivy-fs-scan.sh`, `.github/scripts/07-image-scan-sbom.sh`, `.github/workflows/Microservice-Ci.yaml`

---

## Additional Security Hardening

- **RBAC**: Kubernetes ServiceAccounts with minimal permissions; Argo CD Projects restrict source repositories and destination namespaces
- **Pod Security**: Kyverno enforces non-root users, resource limits, and blocks privileged containers
- **TLS/Encryption**: RDS encryption at rest enabled; EKS control plane encryption in transit; S3 bucket encryption for artifact storage
- **Least-Privilege IAM**: IRSA roles scoped to specific resources (RDS secret ARN, ECR repository ARN); GitHub Actions role limited to ECR push and S3 upload
- **Secret Rotation**: AWS Secrets Manager supports automatic rotation; External Secrets Operator refreshes Kubernetes Secrets on rotation interval

