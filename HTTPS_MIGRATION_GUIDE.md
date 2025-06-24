# HTTPS Migration Guide: VM Traefik → k3s Traefik

## Overview
This guide documents the migration from VM-based Traefik SSL termination to native k3s Traefik HTTPS handling.

## Changes Made

### 1. Traefik Configuration Updates
- **File**: `ingress/traefik-helm-values.yaml`
- **Changes**:
  - Added `websecure` entryPoint on port 443
  - Configured automatic HTTP → HTTPS redirect
  - Added Let's Encrypt ACME configuration with Route53 DNS challenge
  - Added wildcard certificate domains for `*.crussell.io`, `*.internal.crussell.io`, `*.k3s.crussell.io`
  - Added AWS environment variables for Route53 access

### 2. Secrets Configuration
- **File**: `ingress/secrets.yaml` (SOPS encrypted)
- **Added**: AWS credentials for Route53 DNS challenge:
  - `aws-access-key-id`
  - `aws-secret-access-key` 
  - `aws-hosted-zone-id`

### 3. IngressRoute Updates
All IngressRoutes have been updated to:
- Use `websecure` entryPoint instead of `web`
- Add `tls.certResolver: letsencrypt` configuration

**Updated Services**:
- Media: Radarr, Sonarr, Prowlarr, Jackett, Jellyseerr
- Productivity: Mealie, Ntfy, Paperless-NGX, Karakeep, Open WebUI
- Development: Forgejo, IT Tools, n8n
- Infrastructure: Home Assistant, MinIO (API & Web), NAS, pgAdmin, Traefik Dashboard
- Monitoring: Grafana, Longhorn

### 4. Application Configuration Updates
- **Forgejo**: Updated `ROOT_URL` from HTTP to HTTPS
- **Ntfy**: Updated `base-url` from HTTP to HTTPS

## Deployment Steps

### Phase 1: Deploy Updated Configuration
```bash
# Apply the updated Traefik configuration
kubectl apply -k ingress/

# Verify Traefik pods are running with new config
kubectl get pods -n traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik
```

### Phase 2: Monitor Certificate Generation
```bash
# Check certificate resolver status
kubectl logs -n traefik -l app.kubernetes.io/name=traefik | grep -i acme

# Verify certificates are being issued
kubectl exec -n traefik deployment/traefik -- ls -la /data/
```

### Phase 3: Test HTTPS Access
Test each service to ensure HTTPS is working:
```bash
# Test a few key services
curl -I https://traefik.internal.crussell.io
curl -I https://homeassistant.crussell.io
curl -I https://mealie.crussell.io
```

### Phase 4: Update DNS/Routing
Once HTTPS is confirmed working in k3s:
1. Update your router/firewall to point domains directly to k3s (192.168.20.240)
2. Or update your external proxy to route to k3s on port 443 instead of 80

### Phase 5: Decommission VM Traefik
After confirming all services work with the new setup:
1. Stop the VM-based Traefik service
2. Update any external routing to bypass the VM
3. Eventually decommission the VM

## Service Mapping

### Public Services (*.crussell.io)
- `homeassistant.crussell.io` → Home Assistant (external)
- `mealie.crussell.io` → Mealie
- `jellyseerr.crussell.io` → Jellyseerr
- `n8n.crussell.io` → n8n

### Internal Services (*.internal.crussell.io)
- `traefik.internal.crussell.io` → Traefik Dashboard
- `grafana.internal.crussell.io` → Grafana
- `longhorn.internal.crussell.io` → Longhorn UI
- `nas.internal.crussell.io` → NAS UI
- `minio.internal.crussell.io` → MinIO Console
- `s3.internal.crussell.io` → MinIO S3 API
- `pgadmin.internal.crussell.io` → pgAdmin
- Plus all media services (Sonarr, Radarr, etc.)

## Verification Checklist

- [ ] Traefik pods running successfully
- [ ] ACME certificates being generated
- [ ] HTTP redirects to HTTPS working
- [ ] All services accessible via HTTPS
- [ ] Certificate auto-renewal configured
- [ ] External routing updated
- [ ] VM Traefik decommissioned

## Rollback Plan

If issues occur, you can quickly rollback by:
1. Reverting `ingress/traefik-helm-values.yaml` to remove HTTPS config
2. Changing all IngressRoutes back to `entryPoints: [web]`
3. Removing `tls:` sections from IngressRoutes
4. Re-enabling the VM-based Traefik

## Notes

- The k3s Traefik will now handle all SSL termination
- Certificates will be stored in the persistent volume at `/data/acme.json`
- Route53 DNS challenge allows for wildcard certificates
- HTTP traffic will automatically redirect to HTTPS
- The VM at 192.168.20.201 can be decommissioned after successful migration