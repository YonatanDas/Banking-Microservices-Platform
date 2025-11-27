# Runbook: Database Backup and Restore

## Overview
This runbook describes procedures for backing up and restoring RDS PostgreSQL databases in the banking platform.

## Prerequisites
- AWS CLI configured with appropriate permissions
- `kubectl` access (for connecting to database)
- Database credentials (from AWS Secrets Manager)

## Backup Procedures

### Automated Backups

RDS automated backups are configured via Terraform:
- **Dev**: 0 days retention (backup_retention_period = 0)
- **Staging**: 7 days retention
- **Production**: 7 days retention (configurable up to 35 days)

Backups are automatically taken daily during the backup window.

### Manual Snapshot

#### Create Snapshot via AWS CLI
```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier <instance-id> \
  --db-snapshot-identifier banking-db-snapshot-$(date +%Y%m%d-%H%M%S) \
  --region us-east-1

# List snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier <instance-id> \
  --region us-east-1
```

#### Create Snapshot via Terraform
Add to `05-terraform/modules/rds/main.tf`:
```hcl
resource "aws_db_snapshot" "manual" {
  db_instance_identifier = aws_db_instance.this.id
  db_snapshot_identifier = "banking-db-manual-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
}
```

### Export Data (Logical Backup)

#### Using kubectl exec
```bash
# Get database credentials from ExternalSecret
kubectl get secret <db-secret-name> -n default -o jsonpath='{.data}' | jq

# Connect to database pod (if using sidecar) or create temporary pod
kubectl run pg-dump --image=postgres:15 --rm -it --restart=Never -- \
  pg_dump -h <rds-endpoint> -U <username> -d <database-name> > backup.sql
```

#### Using psql directly
```bash
# Get RDS endpoint
aws rds describe-db-instances \
  --db-instance-identifier <instance-id> \
  --query 'DBInstances[0].Endpoint.Address' \
  --region us-east-1

# Export database
PGPASSWORD=<password> pg_dump -h <rds-endpoint> -U <username> -d <database-name> > backup-$(date +%Y%m%d).sql
```

## Restore Procedures

### From Automated Backup

#### Point-in-Time Recovery
```bash
# Restore to specific point in time
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier <source-instance-id> \
  --target-db-instance-identifier <new-instance-id> \
  --restore-time <timestamp> \
  --region us-east-1

# Example timestamp: 2024-01-15T10:30:00Z
```

#### From Snapshot
```bash
# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier <new-instance-id> \
  --db-snapshot-identifier <snapshot-id> \
  --region us-east-1
```

### From Manual Snapshot

```bash
# List available snapshots
aws rds describe-db-snapshots \
  --db-snapshot-identifier <snapshot-id> \
  --region us-east-1

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier <new-instance-id> \
  --db-snapshot-identifier <snapshot-id> \
  --db-instance-class db.t3.medium \
  --region us-east-1
```

### From Logical Backup (SQL File)

```bash
# Create new database instance (if needed)
# Or connect to existing instance

# Restore from SQL file
PGPASSWORD=<password> psql -h <rds-endpoint> -U <username> -d <database-name> < backup.sql

# Or using kubectl
kubectl run pg-restore --image=postgres:15 --rm -it --restart=Never -- \
  psql -h <rds-endpoint> -U <username> -d <database-name> < backup.sql
```

## Disaster Recovery Scenarios

### Scenario 1: Database Corruption

1. **Identify corruption:**
   ```bash
   # Check database logs
   aws rds describe-db-log-files \
     --db-instance-identifier <instance-id> \
     --region us-east-1
   ```

2. **Restore from latest snapshot:**
   ```bash
   # Find latest snapshot
   aws rds describe-db-snapshots \
     --db-instance-identifier <instance-id> \
     --sort-by=SnapshotCreateTime \
     --region us-east-1
   
   # Restore
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier <new-instance-id> \
     --db-snapshot-identifier <latest-snapshot-id> \
     --region us-east-1
   ```

3. **Update application connection strings:**
   - Update ExternalSecret with new endpoint
   - Restart pods to pick up new credentials

### Scenario 2: Accidental Data Deletion

1. **Stop writes immediately:**
   ```bash
   # Scale down services
   kubectl scale deployment accounts --replicas=0 -n default
   kubectl scale deployment cards --replicas=0 -n default
   kubectl scale deployment loans --replicas=0 -n default
   ```

2. **Perform point-in-time recovery:**
   ```bash
   aws rds restore-db-instance-to-point-in-time \
     --source-db-instance-identifier <source-instance-id> \
     --target-db-instance-identifier <restored-instance-id> \
     --restore-time <time-before-deletion> \
     --region us-east-1
   ```

3. **Verify data:**
   ```bash
   # Connect and verify
   kubectl run pg-verify --image=postgres:15 --rm -it --restart=Never -- \
     psql -h <restored-endpoint> -U <username> -d <database-name> -c "SELECT COUNT(*) FROM accounts;"
   ```

4. **Switch traffic to restored instance:**
   - Update ExternalSecret
   - Scale services back up

### Scenario 3: Complete Database Loss

1. **Restore from latest snapshot:**
   ```bash
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier <new-instance-id> \
     --db-snapshot-identifier <latest-snapshot-id> \
     --region us-east-1
   ```

2. **Recreate database if needed:**
   ```bash
   kubectl run pg-create --image=postgres:15 --rm -it --restart=Never -- \
     psql -h <rds-endpoint> -U <username> -d postgres -c "CREATE DATABASE <database-name>;"
   ```

3. **Restore from logical backup (if available):**
   ```bash
   PGPASSWORD=<password> psql -h <rds-endpoint> -U <username> -d <database-name> < latest-backup.sql
   ```

## Verification

### Verify Backup
```bash
# Check snapshot status
aws rds describe-db-snapshots \
  --db-snapshot-identifier <snapshot-id> \
  --region us-east-1

# Verify backup file integrity
pg_restore --list backup.sql | head -20
```

### Verify Restore
```bash
# Connect to restored database
kubectl run pg-verify --image=postgres:15 --rm -it --restart=Never -- \
  psql -h <rds-endpoint> -U <username> -d <database-name>

# Check table counts
SELECT 
  schemaname,
  tablename,
  n_live_tup as row_count
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
```

## Best Practices

1. **Regular Backups:**
   - Automated daily backups (RDS)
   - Weekly manual snapshots for critical data
   - Monthly logical backups for long-term retention

2. **Backup Testing:**
   - Test restore procedures quarterly
   - Verify backup integrity
   - Document restore times (RTO)

3. **Backup Storage:**
   - Store logical backups in S3 with versioning
   - Enable encryption for backups
   - Cross-region replication for critical backups

4. **Monitoring:**
   - Alert on backup failures
   - Monitor backup storage usage
   - Track restore times

## Troubleshooting

### Backup Failures
```bash
# Check RDS events
aws rds describe-events \
  --source-identifier <instance-id> \
  --source-type db-instance \
  --region us-east-1

# Check storage space
aws rds describe-db-instances \
  --db-instance-identifier <instance-id> \
  --query 'DBInstances[0].AllocatedStorage' \
  --region us-east-1
```

### Restore Failures
```bash
# Check restore status
aws rds describe-db-instances \
  --db-instance-identifier <restored-instance-id> \
  --region us-east-1

# Check logs
aws rds describe-db-log-files \
  --db-instance-identifier <restored-instance-id> \
  --region us-east-1
```

## Contacts

- Database Team: [contact information]
- Platform Team: [contact information]
- AWS Support: [if applicable]

