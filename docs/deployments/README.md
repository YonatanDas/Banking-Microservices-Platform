# Deployment Records

This directory contains deployment audit trail records for all deployments to staging and production environments.

## Directory Structure

```
docs/deployments/
├── stag/          # Staging deployment records
├── prod/          # Production deployment records
└── README.md      # This file
```

## Record Format

Each deployment record is a Markdown file with the following naming convention:
```
{service}-{timestamp}.md
```

Example: `accounts-2024-01-15T10:30:00Z.md`

## Record Contents

Each deployment record includes:
- Service name and environment
- Image tag deployed
- Deployment timestamp (UTC)
- Deployed by (GitHub user)
- Deployment reason/change ticket
- Git commit and workflow run information
- Post-deployment verification status

## Accessing Records

### View All Deployments for a Service

```bash
ls docs/deployments/prod/ | grep accounts
```

### View Recent Deployments

```bash
ls -lt docs/deployments/prod/ | head -10
```

### View Specific Deployment

```bash
cat docs/deployments/prod/accounts-2024-01-15T10:30:00Z.md
```

## Retention

Deployment records are retained for **365 days** for audit and compliance purposes.

## Related Documentation

- [Deployment Process](../runbooks/deployment-process.md)
- [Rollback Procedures](../runbooks/rollback-procedures.md)

