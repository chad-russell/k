# TODO: k3s Cluster Improvements & Next Steps

## 1. Infrastructure & Configuration Management

- [ ] **Capture current Longhorn configuration in YAML**
  - Export as much of the current Longhorn setup as possible (volumes, settings, etc.)
  - Store in version control for reproducibility and disaster recovery
- [ ] **Adopt Helm Secrets for sensitive values**
  - Store Route53 credentials and ACME email securely using Helm Secrets or SOPS
  - Remove all hardcoded secrets from versioned YAML
- [ ] **Move toward GitOps for cluster management**
  - Use tools like ArgoCD or Flux to manage cluster state from Git
  - Integrate Helm Secrets into GitOps workflow

## 2. Core Services

- [ ] **Stand up a highly available Postgres database**
  - Use a Helm chart or operator (e.g., Zalando, CrunchyData, Bitnami)
  - Ensure data is stored on Longhorn volumes for HA and backup
  - Configure backups and monitoring

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
