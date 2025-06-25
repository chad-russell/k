# Immich Database Setup Guide

This guide walks you through manually setting up the PostgreSQL database for Immich. This approach allows you to verify each step and troubleshoot any issues.

## Prerequisites

- Access to your k3s cluster
- SOPS configured for decrypting secrets
- PostgreSQL cluster running in the `postgres-system` namespace

## Step 1: Get PostgreSQL Superuser Password

First, we need to get the PostgreSQL superuser password from your existing secrets:

```bash
# Decrypt and view the postgres password
sops -d postgres/secrets.yaml
```

Look for the `password` field under `stringData`. Copy this password - you'll need it for the next steps.

## Step 2: Connect to PostgreSQL

Connect to your PostgreSQL cluster as the superuser:

```bash
# Connect to the PostgreSQL cluster
kubectl exec -it postgres-cluster-1 -n postgres-system -- psql -U postgres
```

If the above doesn't work, try finding the correct pod name:
```bash
kubectl get pods -n postgres-system
# Then use the correct pod name
kubectl exec -it <pod-name> -n postgres-system -- psql -U postgres
```

## Step 3: Create Immich Database User

Create a dedicated user for Immich. You'll need to choose a strong password:

```sql
-- Create the immich user (replace 'your_secure_password' with a strong password)
CREATE USER immich WITH PASSWORD 'your_secure_password';
```

**Note**: Remember this password - you'll need to add it to the Immich secrets later.

## Step 4: Create Immich Database

Create the database and set the immich user as the owner:

```sql
-- Create the immich database
CREATE DATABASE immich OWNER immich;

-- Grant all privileges on the database to the immich user
GRANT ALL PRIVILEGES ON DATABASE immich TO immich;
```

## Step 5: Connect to Immich Database

Switch to the immich database to install extensions:

```sql
-- Connect to the immich database
\c immich
```

## Step 6: Install Required Extensions

Install the PostgreSQL extensions that Immich needs:

```sql
-- Install pgvector extension (for AI/ML features)
CREATE EXTENSION IF NOT EXISTS vector;

-- Install earthdistance extension (for geographic features)
CREATE EXTENSION IF NOT EXISTS earthdistance CASCADE;

-- Install pg_trgm extension (for text search)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

**Note**: If the `vector` extension fails, that's okay for now. Immich will work without it, but you'll miss out on AI-powered search features. You can install pgvector later if needed.

## Step 7: Grant Schema Permissions

Grant the necessary permissions on the public schema:

```sql
-- Grant usage and create permissions on the public schema
GRANT USAGE ON SCHEMA public TO immich;
GRANT CREATE ON SCHEMA public TO immich;
```

## Step 8: Verify Setup

Let's verify everything is set up correctly:

```sql
-- List databases (should see 'immich')
\l

-- List users (should see 'immich')
\du

-- List extensions in the immich database
\dx
```

## Step 9: Exit PostgreSQL

Exit the PostgreSQL session:

```sql
\q
```

## Step 10: Update Immich Secrets

Now update the Immich secrets with the database password you created:

```bash
# Edit the secrets file
vim apps/productivity/immich/secrets.yaml
```

Update the `db-password` field with the password you used in Step 3.

## Step 11: Encrypt Secrets

Encrypt the secrets file with SOPS:

```bash
sops -e -i apps/productivity/immich/secrets.yaml
```

## Step 12: Test Database Connection

Let's test that the immich user can connect to the database:

```bash
# Get the immich password you just set
IMMICH_PASSWORD="your_secure_password"  # Replace with actual password

# Test connection
kubectl exec -it postgres-cluster-1 -n postgres-system -- psql -h localhost -U immich -d immich -c "SELECT version();"
```

You'll be prompted for the password. If it connects successfully, you're all set!

## Troubleshooting

### If pgvector extension is not available:

The `vector` extension might not be installed in your PostgreSQL cluster. You can:

1. **Check if it's available**:
   ```sql
   SELECT * FROM pg_available_extensions WHERE name = 'vector';
   ```

2. **Install pgvector manually** (if needed):
   This requires installing the pgvector extension in your PostgreSQL cluster, which might require rebuilding the PostgreSQL image or using a different base image.

3. **Continue without it**: Immich will work fine without pgvector, you'll just miss AI-powered search features.

### If connection fails:

1. **Check PostgreSQL pod status**:
   ```bash
   kubectl get pods -n postgres-system
   ```

2. **Check PostgreSQL logs**:
   ```bash
   kubectl logs postgres-cluster-1 -n postgres-system
   ```

3. **Verify service is accessible**:
   ```bash
   kubectl get svc -n postgres-system
   ```

## Next Steps

Once the database is set up successfully:

1. Deploy Immich: `kubectl apply -k apps/productivity/immich/`
2. Check pod status: `kubectl get pods -n immich`
3. Access Immich at: `https://immich.internal.crussell.io`

## Summary

You should now have:
- ✅ `immich` database created
- ✅ `immich` user with proper permissions
- ✅ Required extensions installed (except possibly `vector`)
- ✅ Immich secrets updated and encrypted
- ✅ Database connection tested 