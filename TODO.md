# TODO: k3s Cluster Improvements & Next Steps

## 1. Infrastructure & Configuration Management ✅ COMPLETED

- [x] **Capture current Longhorn configuration in YAML**
  - Export as much of the current Longhorn setup as possible (volumes, settings, etc.)
  - Store in version control for reproducibility and disaster recovery
- [x] **Adopt Helm Secrets for sensitive values**
  - Store Route53 credentials and ACME email securely using Helm Secrets or SOPS
  - Remove all hardcoded secrets from versioned YAML
- [x] **Move toward GitOps for cluster management**
  - Use tools like ArgoCD or Flux to manage cluster state from Git
  - Integrate Helm Secrets into GitOps workflow

**Status**: All infrastructure and GitOps foundations are complete. Flux is managing the cluster declaratively with SOPS encryption for secrets, Longhorn is providing HA storage, and Traefik ingress controller is deployed and working.

## 2. Core Services

- [ ] **Stand up a highly available Postgres database**
  - Ensure data is stored on Longhorn volumes for HA and backup
  - Configure backups and monitoring
  - Would you like me to help you create the CloudNativePG configuration? Here's what we'd do:
    - Create a postgres directory in your repo
    - Configure the CloudNativePG operator via Helm
    - Set up a PostgreSQL cluster with HA configuration
    - Encrypt database credentials with SOPS
    - Configure backups to Longhorn volumes or S3
    - Add monitoring integration
    - The setup would give you:
    - Primary + 2 replicas for true HA
    - Automatic failover (< 30 seconds)
    - Read-only replicas for performance
    - Connection pooling for efficiency
    - Encrypted backups with point-in-time recovery
    - Would you like me to start setting this up? I can create the configuration files and walk you through the deployment!

## 3. Applications & Data Migration

- [ ] **Install paperless-ngx via Helm or manifests**
  - Deploy in the cluster, using Longhorn for persistent storage
  - Configure ingress, secrets, and environment variables securely
- [ ] **Migrate data from old Docker-based paperless-ngx**
  - Plan and execute data migration to the new cluster
  - Validate data integrity and application functionality

---

**Prioritization rationale:**

1. Secure and capture current state (Longhorn, secrets)
2. Move to GitOps for safer, auditable changes
3. Deploy core services (Postgres) with HA and backup
4. Deploy and migrate applications (paperless-ngx)
