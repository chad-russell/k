# MCP Jungle

MCP Jungle is deployed as a standard Kubernetes Deployment in the `mcpjungle`
namespace and exposed through Traefik at `mcpjungle.internal.crussell.io`.

## Kubernetes Resources

- `namespace.yaml` – dedicated namespace
- `secrets.yaml` – `DATABASE_URL` secret (encrypt with SOPS before use)
- `config-secret.yaml` – Admin access token file mounted at `/root/.mcpjungle.conf`
- `server-configs.yaml` – Secret containing MCP server JSON definitions mounted at `/config`
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

## Persisting the Admin Token

The `/mcpjungle init-server` command writes an admin access token to
`/root/.mcpjungle.conf`. Because container root filesystems are ephemeral, the
Deployment mounts `config-secret.yaml` at that path so the token survives pod
restarts.

1. Run the init command once inside the running pod:
   ```bash
   kubectl exec -it deploy/mcpjungle -n mcpjungle -- /mcpjungle init-server
   ```

2. Capture the generated config file:
   ```bash
   kubectl exec deploy/mcpjungle -n mcpjungle -- cat /root/.mcpjungle.conf
   ```

3. Edit `config-secret.yaml` with SOPS and paste the file contents:
   ```bash
   sops apps/development/mcpjungle/config-secret.yaml
   ```
   Replace `CHANGE_ME_TOKEN` with the `access_token` value (and adjust
   `registry_url` if needed). Save to re-encrypt.

4. Redeploy (Flux will reconcile automatically) so the pod restarts with the
   mounted token file.

## Registering MCP Servers

JSON definitions for stdio/SSE MCP servers live in `server-configs.yaml` and are
mounted into the pod at `/config`. Each key becomes a file (for
example, `server-example.json` → `/mcpjungle/config/server-example.json`).

1. Edit the secret with SOPS and add/update JSON entries:
   ```bash
   sops apps/development/mcpjungle/server-configs.yaml
   ```

2. For every server, keep the JSON structure:
   ```json
   {
     "name": "<name>",
     "transport": "stdio",
     "description": "<description>",
     "command": "<command>",
     "args": ["arg1", "arg2"],
     "env": {"KEY": "value"}
   }
   ```

3. After saving, run `just sync` (or wait for Flux) so the new secret version is
   applied and the pod restarts.

4. Register the server inside the pod using the mounted file:
   ```bash
   kubectl exec deploy/mcpjungle -n mcpjungle -- \
     /mcpjungle register -c /mcpjungle/config/<file>.json
   ```

## Post-Deployment

- Verify that the pod becomes ready:
  ```bash
  kubectl get pods -n mcpjungle
  ```
- Confirm the app is reachable through Traefik at
  `https://mcpjungle.internal.crussell.io`.
