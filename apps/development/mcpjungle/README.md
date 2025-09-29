# MCP Jungle

MCP Jungle is deployed as a standard Kubernetes Deployment in the `mcpjungle`
namespace and exposed through Traefik at `mcpjungle.internal.crussell.io`.

## Kubernetes Resources

- `namespace.yaml` – dedicated namespace
- `secrets.yaml` – `DATABASE_URL` secret (encrypt with SOPS before use)
- `deployment.yaml` – application Deployment and ClusterIP Service on port 8080
- `ingress.yaml` – Traefik IngressRoute for TLS termination

## Database Setup

The cluster already runs CloudNativePG and exposes a read/write endpoint at
`postgres-cluster-rw.postgres-system.svc.cluster.local:5432`. To provision the
database and user for MCP Jungle:

1. Identify the current primary pod:
   ```bash
   kubectl get cluster postgres-cluster -n postgres-system \
     -o jsonpath='{.status.currentPrimary}'
   ```

2. Connect to the primary using `psql`:
   ```bash
   kubectl exec -it <primary-pod-name> -n postgres-system -- \
     psql -U postgres
   ```

3. Inside `psql`, create the database and application role (replace
   `STRONG_PASSWORD` with a generated password):
   ```sql
   CREATE DATABASE mcpjungle;
   CREATE USER mcpjungle WITH PASSWORD 'STRONG_PASSWORD';
   GRANT ALL PRIVILEGES ON DATABASE mcpjungle TO mcpjungle;
   ALTER DATABASE mcpjungle OWNER TO mcpjungle;
   \c mcpjungle
   GRANT ALL ON SCHEMA public TO mcpjungle;
   ```

4. Update the Kubernetes secret with the connection string. Run:
   ```bash
   sops apps/development/mcpjungle/secrets.yaml
   ```
   Then set `DATABASE_URL` to:
   ```
   postgresql://mcpjungle:STRONG_PASSWORD@postgres-cluster-rw.postgres-system.svc.cluster.local:5432/mcpjungle
   ```

5. Save the file – SOPS will re-encrypt it automatically. Commit the encrypted
   secret and allow Flux to reconcile. The Deployment will reference the
   `mcpjungle-postgres` secret once it is present in the cluster.

## Post-Deployment

- Verify that the pod becomes ready:
  ```bash
  kubectl get pods -n mcpjungle
  ```
- Confirm the app is reachable through Traefik at
  `https://mcpjungle.internal.crussell.io`.
