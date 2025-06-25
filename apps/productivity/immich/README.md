# Immich Deployment

This directory contains the Kubernetes manifests for deploying [Immich](https://immich.app/), a high performance self-hosted photo and video backup solution.

## Prerequisites

1. **PostgreSQL with pgvector extension**: Immich requires PostgreSQL with the `vector` extension. This setup uses your existing CloudNativePG cluster.

2. **NFS Storage**: Immich stores photos/videos on your NAS via NFS (`192.168.20.31:/mnt/tank/photos`).

3. **SOPS encryption**: The secrets file needs to be encrypted using SOPS.

## Setup Instructions

### 1. Update PostgreSQL password in database-init.yaml

The database initialization job needs the PostgreSQL superuser password. You'll need to:

1. Get the PostgreSQL password from your existing secrets:
   ```bash
   # Decrypt and view the postgres password
   sops -d postgres/secrets.yaml | grep password
   ```

2. Edit the database-init.yaml file and replace `REPLACE_WITH_POSTGRES_PASSWORD` with the actual password:
   ```bash
   vim apps/productivity/immich/database-init.yaml
   ```

### 2. Encrypt the secrets file

Update the Immich database password in `secrets.yaml`, then encrypt it:

```bash
# Edit the password in secrets.yaml
vim apps/productivity/immich/secrets.yaml

# Encrypt the file with SOPS
sops -e -i apps/productivity/immich/secrets.yaml
```

### 3. Initialize the database

The database initialization job will:
- Create the `immich` database
- Create the `immich` user with the password from secrets
- Install required PostgreSQL extensions (`vector`, `earthdistance`, `pg_trgm`)

### 4. Deploy

Deploy using FluxCD (if you have it configured) or apply manually:

```bash
# Apply the kustomization
kubectl apply -k apps/productivity/immich/
```

### 5. Verify deployment

Check that all pods are running:

```bash
kubectl get pods -n immich
```

Expected pods:
- `immich-server-*` - Main Immich server
- `immich-machine-learning-*` - ML service for face recognition, etc.
- `immich-redis-*` - Redis cache

### 6. Access Immich

Once deployed, Immich will be available at:
- **URL**: https://immich.internal.crussell.io
- **Initial Setup**: Follow the web setup wizard to create your admin account

## Configuration

### Storage

The configuration uses:
- **Library Storage**: NFS mount to `192.168.20.31:/mnt/tank/photos` for photos/videos
- **ML Cache**: 10GB Longhorn PVC for machine learning models (fast local storage)
- **Redis**: 1GB Longhorn PVC for Redis persistence

The photos and videos are stored directly on your NAS, so they're accessible from other applications and easily backed up with your existing NAS backup strategy.

### Resources

Default resource limits:
- **Server**: 2 CPU cores, 2GB RAM
- **Machine Learning**: 2 CPU cores, 4GB RAM

Adjust in `helm-release.yaml` based on your cluster capacity.

### Database

The setup connects to your existing PostgreSQL cluster:
- **Host**: `postgres-cluster-rw.postgres-system.svc.cluster.local`
- **Database**: `immich`
- **User**: `immich` (from secrets)

## Troubleshooting

### Database Connection Issues

If Immich can't connect to the database:

1. Check if the database initialization job completed:
   ```bash
   kubectl get jobs -n immich
   kubectl logs job/immich-db-init -n immich
   ```

2. Verify the database exists:
   ```bash
   kubectl exec -it postgres-cluster-1 -n postgres-system -- psql -U postgres -l
   ```

### NFS Storage Issues

If pods are stuck in pending due to NFS mount issues:

1. Check if the NFS share is accessible from the cluster nodes:
   ```bash
   # Test NFS mount from a cluster node
   showmount -e 192.168.20.31
   ```

2. Verify the `/mnt/tank/photos` directory exists on your NAS

3. Check pod events for mount errors:
   ```bash
   kubectl describe pod <pod-name> -n immich
   ```

### Storage Issues

If pods are stuck in pending due to storage:

1. Check PVC status (for ML cache and Redis):
   ```bash
   kubectl get pvc -n immich
   ```

2. Ensure Longhorn is working:
   ```bash
   kubectl get pods -n longhorn-system
   ```

### Extension Issues

If you get errors about missing extensions, you may need to install pgvector manually:

```bash
# Connect to PostgreSQL as superuser
kubectl exec -it postgres-cluster-1 -n postgres-system -- psql -U postgres -d immich

# Install extensions (you may need to install pgvector first)
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS earthdistance CASCADE;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

**Note**: The `vector` extension (pgvector) may need to be installed separately in your PostgreSQL cluster. If it's not available, Immich will still work but without vector-based features like smart search.

## Mobile App

After setup, you can use the Immich mobile app:
- **iOS**: Available on the App Store
- **Android**: Available on Google Play Store or F-Droid

Configure the mobile app to connect to `https://immich.internal.crussell.io`.

## Backup

With NFS storage, your backup strategy is simplified:
1. **Database**: Use your PostgreSQL backup strategy
2. **Photos/Videos**: Already on your NAS at `/mnt/tank/photos` - use your existing NAS backup
3. **Configuration**: The Kubernetes manifests in this directory

## Updates

To update Immich:

1. Update the `image.tag` and chart `version` in `helm-release.yaml`
2. Apply the changes:
   ```bash
   kubectl apply -k apps/productivity/immich/
   ```

Check the [Immich releases](https://github.com/immich-app/immich/releases) for version compatibility.

## Security Notes

1. **Database Password**: Make sure to use a strong password for the Immich database user
2. **NFS Security**: Ensure your NFS share has appropriate access controls
3. **Network**: The setup uses internal cluster networking and Traefik for TLS termination

## NFS Mount Details

The NFS mount is configured with optimized settings:
- **NFS Version**: 4.1
- **Read/Write Size**: 1MB (1048576 bytes) for better performance
- **Mount Options**: `hard`, `intr`, `noatime` for reliability and performance 