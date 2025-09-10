# Highly Available PostgreSQL Setup

This directory contains the configuration for a highly available PostgreSQL cluster using CloudNativePG operator.

## Overview

The setup provides:

- **Primary + 2 replicas** for true high availability
- **Automatic failover** (< 30 seconds)
- **Read-only replicas** for performance optimization
- **Load balancing** for read/write separation
- **Encrypted backups** with point-in-time recovery
- **Longhorn storage** integration for persistent volumes
- **Monitoring** with Prometheus metrics

## Architecture

- **3 PostgreSQL instances**: 1 primary + 2 replicas
- **Anti-affinity rules**: Instances spread across different nodes
- **Storage**: 20Gi per instance using Longhorn storage class
- **Version**: PostgreSQL 16.2
- **Backup**: S3-compatible storage support (currently disabled)

## Services

- `postgres-cluster-rw`: Read-write service (connects to primary)
- `postgres-cluster-ro`: Read-only service (connects to replicas)

## Initial Setup

### 1. Update Secrets

Before deploying, you need to update the encrypted secrets with your actual values:

```bash
# Decrypt the secrets file for editing
sops postgres/secrets.yaml

# Update the following values:
# - PostgreSQL superuser password
# - Application user password
# - Backup credentials (S3 access keys)
# - Backup encryption key (32 characters)

# The file will be automatically re-encrypted when you save
```

### 2. Configure Backup Storage

Update the backup configuration in `cluster.yaml`:

```yaml
backup:
  barmanObjectStore:
    destinationPath: "s3://your-actual-backup-bucket/postgres"
    # ... rest of config
```

If you don't want S3 backups initially, you can comment out the entire `backup` section.

### 3. Deploy

The PostgreSQL cluster will be deployed automatically via GitOps when you commit and push the changes:

```bash
git add postgres/
git commit -m "Add highly available PostgreSQL cluster"
git push
```

## Monitoring Deployment

Check the deployment status:

```bash
# Watch operator installation
kubectl get pods -n postgres-system -w

# Check cluster status
kubectl get cluster -n postgres-system

# View cluster details
kubectl describe cluster postgres-cluster -n postgres-system

# Check pod status
kubectl get pods -n postgres-system -l postgresql=postgres-cluster
```

## Connecting to PostgreSQL

### From within the cluster:

**Write operations** (connects to primary):

```
Host: postgres-cluster-rw.postgres-system.svc.cluster.local
Port: 5432
Database: app_db
Username: app_user
Password: [from secrets]
```

**Read operations** (connects to replicas):

```
Host: postgres-cluster-ro.postgres-system.svc.cluster.local
Port: 5432
Database: app_db
Username: app_user
Password: [from secrets]
```

### Connection strings:

**Read-write**:

```
postgresql://app_user:password@postgres-cluster-rw.postgres-system.svc.cluster.local:5432/app_db
```

**Read-only**:

```
postgresql://app_user:password@postgres-cluster-ro.postgres-system.svc.cluster.local:5432/app_db
```

## Administrative Access

### Get superuser password:

```bash
kubectl get secret postgres-credentials -n postgres-system -o jsonpath='{.data.password}' | base64 -d
```

### Connect as superuser:

**For READ-WRITE operations (DDL, DML, admin tasks):**

First, find the current primary pod (this can change due to failovers):

```bash
kubectl get cluster postgres-cluster -n postgres-system -o jsonpath='{.status.currentPrimary}'
```

Then connect to the primary pod:

```bash
# Replace postgres-cluster-X with the actual primary pod name from above
kubectl exec -it postgres-cluster-X -n postgres-system -- psql -U postgres -d postgres
```

**For READ-ONLY operations (queries, monitoring):**

You can connect to any replica pod:

```bash
kubectl exec -it postgres-cluster-1 -n postgres-system -- psql -U postgres -d app_db
```

**Important:** Always connect to the primary pod for operations like:
- `DROP DATABASE`, `CREATE DATABASE`
- `DROP USER`, `CREATE USER` 
- `ALTER` statements
- Data modifications (`INSERT`, `UPDATE`, `DELETE`)

Connecting to replica pods will give you "read-only transaction" errors for write operations.

## Backup and Recovery

### Manual backup:

```bash
kubectl annotate cluster postgres-cluster -n postgres-system \
  cnpg.io/backup="$(date +%Y%m%d%H%M%S)"
```

### List backups:

```bash
kubectl get backup -n postgres-system
```

### Point-in-time recovery:

See CloudNativePG documentation for detailed recovery procedures.

## Failover Testing

### Manual switchover (planned):

```bash
# Promote a specific replica to primary (replace X with desired pod number)
kubectl cnpg promote postgres-cluster-X -n postgres-system
```

### Simulate failure:

```bash
# Delete current primary pod to test automatic failover
# First find the primary:
PRIMARY=$(kubectl get cluster postgres-cluster -n postgres-system -o jsonpath='{.status.currentPrimary}')
kubectl delete pod $PRIMARY -n postgres-system
```

The cluster should automatically promote a replica to primary within ~30 seconds.

## Monitoring

The cluster exposes Prometheus metrics on the `/metrics` endpoint. Key metrics include:

- `cnpg_pg_replication_lag`: Replication lag in seconds
- `cnpg_pg_database_size_bytes`: Database size
- `cnpg_pg_locks_count`: Lock statistics
- Standard PostgreSQL metrics

## Troubleshooting

### Check cluster status:

```bash
kubectl get cluster postgres-cluster -n postgres-system -o yaml
```

### View operator logs:

```bash
kubectl logs -n postgres-system -l app.kubernetes.io/name=cloudnative-pg
```

### Check pod logs:

```bash
kubectl logs postgres-cluster-1 -n postgres-system
```

### View cluster events:

```bash
kubectl get events -n postgres-system --sort-by='.lastTimestamp'
```

## Performance Tuning

The cluster is pre-configured with optimized settings for a typical workload:

- `shared_buffers: 256MB`
- `effective_cache_size: 1GB`
- `max_connections: 200`
- Read/write service separation
- Logging configured for performance monitoring

Adjust these values in `cluster.yaml` based on your specific workload requirements.

## Security

- All sensitive data encrypted with SOPS
- Role-based access control configured
- Role-based access control
- Network policies can be added for additional isolation
- Backup encryption enabled

## Scaling

To scale the cluster:

1. Update `instances` count in `cluster.yaml`
2. Commit and push changes
3. GitOps will handle the scaling automatically

**Note**: Always use odd numbers for instances to avoid split-brain scenarios.
