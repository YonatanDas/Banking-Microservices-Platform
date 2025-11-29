# Platform Configuration Guide

This document describes all configurable values for the platform template. Customize these values to adapt the platform for your specific use case.

## Overview

The platform is designed to be generic and reusable. All domain-specific values (service names, project names, AWS account IDs, etc.) are configurable through variables and configuration files.

## Configuration Files

### 1. Terraform Configuration

**Location**: `05-terraform/environments/{env}/*.tfvars`

**Key Variables**:
- `microservices`: List of service names (e.g., `["accounts", "cards", "loans", "gatewayserver"]`)
- `name_prefix`: Prefix for resource names (e.g., `"banking"` or `""` for no prefix)
- `project_name`: Project name for tagging (e.g., `"Banking-App"`)
- `db_name_suffix`: Database name suffix (e.g., `"bank"`)
- `service_registry`: Map of service configurations (see structure below)

**Service Registry Structure**:
```hcl
service_registry = {
  accounts = {
    service_account_name = "accounts-sa"
    port                 = 8080
    needs_rds_access     = true
    helm_name            = "accounts"  # Optional, defaults to service name
  }
  # ... other services
}
```

### 2. CI/CD Configuration

**Location**: `.github/config/services.yaml`

**Structure**:
```yaml
services:
  service-name:
    path: "path/to/service"
    helm_name: "helm-chart-name"
    dockerfile: "Dockerfile"
    service_account_name: "service-sa"
    port: 8080
```

### 3. Helm Configuration

**Location**: `06-helm/environments/{env}-env/values.yaml`

**Global Variables**:
- `global.ecrRegistry`: ECR registry URL (computed from AWS account ID and region)
- `global.configMapName`: ConfigMap name (e.g., `"platform-config"`)
- `global.awsAccountId`: AWS account ID
- `global.aws.region`: AWS region
- `global.environment`: Environment name (dev/stag/prod)

### 4. GitOps Configuration

**Location**: `07-gitops/config.yaml`

**Variables**:
- `repository_url`: Git repository URL
- `project_prefix`: Prefix for ArgoCD projects (e.g., `"platform"` or `""`)
- `application_naming_pattern`: Pattern for application names

### 5. Monitoring Configuration

**Location**: `08-monitoring/prometheus-operator/values/{env}.yaml`

**Variables**:
- `platformName`: Platform name for dashboards (e.g., `"Platform"`)
- `serviceLabelSelector`: Label selector for service discovery

### 6. Security Configuration

**Location**: `09-kyverno/config/configmap.yaml`

**Variables**:
- `allowedRegistry`: Allowed container registry pattern

## Adding a New Microservice

To add a new microservice, follow these steps:

1. **Add to Terraform** (`05-terraform/environments/{env}/*.tfvars`):
   ```hcl
   microservices = ["accounts", "cards", "loans", "new-service"]
   
   service_registry = {
     # ... existing services
     new-service = {
       service_account_name = "new-service-sa"
       port                 = 8080
       needs_rds_access     = true
     }
   }
   ```

2. **Add to CI/CD** (`.github/config/services.yaml`):
   ```yaml
   services:
     new-service:
       path: "05-new-service"
       helm_name: "new-service"
       dockerfile: "Dockerfile"
       service_account_name: "new-service-sa"
       port: 8080
   ```

3. **Create Helm Chart** (`06-helm/bankingapp-services/new-service/`):
   - Create `Chart.yaml` and `values.yaml`
   - Use `bankingapp-common` as a dependency

4. **Add to Environment Chart** (`06-helm/environments/{env}-env/Chart.yaml`):
   - Add service as a dependency

5. **Create GitOps Application** (`07-gitops/{env}/applications/`):
   - Create application manifest (or use template)

6. **Update Monitoring** (if needed):
   - Service will be auto-discovered via labels
   - Update dashboards if custom panels needed

## Naming Conventions

- **Service Names**: Use lowercase, hyphenated (e.g., `user-service`)
- **Resource Names**: Use `${name_prefix}-${resource}-${environment}` pattern
- **Helm Charts**: Use service name as chart name
- **Kubernetes Labels**: Use `app: ${service_name}` as primary label

## Environment-Specific Overrides

Each environment can override default values:

- **Dev**: Lower resource limits, no deletion protection
- **Staging**: Production-like but with relaxed policies
- **Production**: Full resource limits, deletion protection, strict policies

## Migration Notes

When migrating from banking-specific to generic:

1. Replace `"banking"` prefix with `${name_prefix}` variable
2. Replace hardcoded service lists with `var.microservices`
3. Replace hardcoded ECR URLs with computed values
4. Update all references to use configuration files

## Validation

Before deploying, validate:

1. All service names match across all configuration files
2. Helm chart dependencies are correct
3. GitOps applications reference correct paths
4. CI/CD workflows can find service paths
5. Terraform variables are properly set

## Support

For questions or issues, refer to:
- Component-specific READMEs in each directory
- Terraform module documentation
- Helm chart values.yaml files

