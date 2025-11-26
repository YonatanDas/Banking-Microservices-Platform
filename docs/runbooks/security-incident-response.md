# Runbook: Security Incident Response

## Overview
This runbook provides procedures for responding to security incidents in the banking microservices platform.

## Prerequisites
- `kubectl` configured with cluster access
- Access to security monitoring tools (Prometheus, Grafana)
- Incident response team contact information

## Incident Classification

### Critical
- Unauthorized access to production systems
- Data breach or exfiltration
- Ransomware or malware detection
- Compromised credentials

### High
- Suspicious network activity
- Failed authentication attempts
- Policy violations (Kyverno)
- Unauthorized image deployments

### Medium
- Vulnerability alerts (Trivy)
- Non-compliant configurations
- Missing security patches

## Initial Response

### 1. Isolate Affected Resources
```bash
# Identify compromised pods
kubectl get pods -n default -o wide

# Delete compromised pod (if identified)
kubectl delete pod <pod-name> -n default

# Scale down affected service
kubectl scale deployment <service-name> --replicas=0 -n default
```

### 2. Preserve Evidence
```bash
# Export pod logs
kubectl logs <pod-name> -n default > /tmp/incident-<pod-name>-logs.txt

# Export pod YAML
kubectl get pod <pod-name> -n default -o yaml > /tmp/incident-<pod-name>.yaml

# Export events
kubectl get events -n default --sort-by='.lastTimestamp' > /tmp/incident-events.txt

# Export network policies
kubectl get networkpolicy -n default -o yaml > /tmp/incident-networkpolicies.yaml
```

### 3. Check Security Policies
```bash
# Check Kyverno policy violations
kubectl get events -n default | grep kyverno

# List all ClusterPolicies
kubectl get clusterpolicies

# Check for privileged pods
kubectl get pods -n default -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext.privileged}{"\n"}{end}'
```

## Specific Incident Types

### Unauthorized Image Deployment

**Symptoms:**
- Image from untrusted registry
- Cosign signature verification failure
- Kyverno policy violation

**Response:**
1. Check Kyverno logs:
   ```bash
   kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno --tail=100 | grep <pod-name>
   ```
2. Verify image signature:
   ```bash
   cosign verify <image-url>
   ```
3. Block image in Kyverno policy
4. Remove unauthorized deployment

### Compromised Service Account

**Symptoms:**
- Unusual AWS API calls
- IAM role assumption from unexpected pods
- CloudTrail alerts

**Response:**
1. Revoke IAM role:
   ```bash
   # Identify ServiceAccount
   kubectl get serviceaccount -n default
   
   # Remove IRSA annotation
   kubectl annotate serviceaccount <sa-name> -n default eks.amazonaws.com/role-arn-
   ```
2. Rotate IAM role credentials
3. Review CloudTrail logs for unauthorized access
4. Update IAM policies to restrict access

### Network Policy Violation

**Symptoms:**
- Unauthorized pod-to-pod communication
- Network policy audit warnings

**Response:**
1. Review NetworkPolicies:
   ```bash
   kubectl get networkpolicy -n default
   kubectl describe networkpolicy <policy-name> -n default
   ```
2. Tighten network policies if needed
3. Block unauthorized traffic
4. Monitor network flows

### Vulnerability Detection

**Symptoms:**
- Trivy scan alerts
- CVE reports in CI/CD
- Security scanning failures

**Response:**
1. Review vulnerability report:
   ```bash
   # Check Trivy scan results in S3 or CI artifacts
   aws s3 ls s3://my-ci-artifacts55/Ci-Artifacts/ --recursive | grep trivy
   ```
2. Assess severity (Critical/High/Medium/Low)
3. Patch or update affected images
4. Re-scan after patching
5. Update base images if needed

## Investigation Steps

### 1. Check Pod Logs
```bash
# Recent logs
kubectl logs <pod-name> -n default --tail=100

# Previous container logs
kubectl logs <pod-name> -n default --previous

# All containers in pod
kubectl logs <pod-name> -n default --all-containers=true
```

### 2. Review Audit Logs
```bash
# EKS control plane logs (if enabled)
aws logs tail /aws/eks/<cluster-name>/cluster --follow

# Kubernetes audit logs
kubectl get events -n default --sort-by='.lastTimestamp'
```

### 3. Check Network Activity
```bash
# List network policies
kubectl get networkpolicy -n default

# Check service endpoints
kubectl get endpoints -n default
```

### 4. Review IAM Activity
```bash
# Check CloudTrail for IAM role usage
aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=<role-arn>

# Review IAM role policies
aws iam get-role-policy --role-name <role-name> --policy-name <policy-name>
```

## Containment

### Immediate Actions
1. Isolate affected pods/services
2. Revoke compromised credentials
3. Block malicious network traffic
4. Scale down affected services

### Short-term Actions
1. Rotate all credentials (database, IAM roles, secrets)
2. Review and tighten security policies
3. Update NetworkPolicies
4. Patch vulnerabilities

### Long-term Actions
1. Conduct post-incident review
2. Update security policies and procedures
3. Enhance monitoring and alerting
4. Implement additional security controls

## Recovery

### 1. Verify System Integrity
```bash
# Check all pods are running
kubectl get pods -n default

# Verify services are healthy
kubectl get svc -n default

# Check Argo CD sync status
kubectl get application -n argocd
```

### 2. Restore Services
```bash
# Scale services back up
kubectl scale deployment <service-name> --replicas=<desired-count> -n default

# Or let Argo CD restore via GitOps
argocd app sync <app-name>
```

### 3. Verify Security Posture
```bash
# Run security scans
trivy image <image-url>

# Check policy compliance
kubectl get clusterpolicies
```

## Reporting

Document the incident with:
- Incident type and severity
- Timeline of events
- Affected resources
- Actions taken
- Root cause (if identified)
- Preventive measures

## Prevention

- Enable all Kyverno policies in Enforce mode
- Regular security scanning (Trivy, Checkov)
- Monitor security alerts (Prometheus)
- Regular credential rotation
- Network policy enforcement
- Image signature verification (Cosign)
- Least-privilege IAM policies
- Regular security audits

## Contacts

- Security Team: [contact information]
- Platform Team: [contact information]
- On-Call Engineer: [contact information]

