# Forgejo Actions Runners Deployment

This directory contains the FluxCD resources to deploy Forgejo Actions runners to your K3s cluster.

## Overview

The Forgejo Actions runners allow you to execute CI/CD workflows locally on your Kubernetes cluster instead of relying on external runners. This provides:

- **Better Performance**: Faster builds with local resources
- **Enhanced Security**: No need to expose secrets to external services
- **Cost Efficiency**: No usage limits or costs for runner minutes
- **Custom Environment**: Full control over the runner environment

## Prerequisites

1. **Forgejo Actions Enabled**: Ensure Actions are enabled in your Forgejo instance
2. **SOPS**: For encrypting the runner registration token
3. **FluxCD**: Already configured (which you have)

## Setup Instructions

### 1. Generate Runner Registration Token

1. Log into your Forgejo instance at `https://forgejo.internal.crussell.io`
2. Navigate to **Site Administration** > **Actions** > **Runners**
3. Click **"Create Runner"**
4. Copy the registration token (it looks like a long string)

### 2. Add Runner Token to Existing Secret

Since you have SOPS configured for `secrets.yaml`, simply add the runner token to your existing secret:

1. Decrypt the existing secrets file:
   ```bash
   sops --decrypt secrets.yaml > temp-secrets.yaml
   ```

2. Edit the decrypted file and add the runner token:
   ```bash
   # Edit temp-secrets.yaml and add this line in the stringData section:
   # RUNNER_TOKEN: "your_actual_registration_token_here"
   nano temp-secrets.yaml
   ```

3. Re-encrypt the file:
   ```bash
   sops --encrypt temp-secrets.yaml > secrets.yaml
   rm temp-secrets.yaml
   ```

### 3. Deploy with FluxCD

Once you've added the runner token to your existing secrets file, deploy using your usual FluxCD workflow:

```bash
flux reconcile kustomization flux-system --with-source
```

### 4. Verify Deployment

Check that the runners are deployed and registered:

```bash
# Check pods
kubectl get pods -n forgejo -l app=act-runner

# Check logs
kubectl logs -n forgejo -l app=act-runner -f

# Check runner status in Forgejo UI
# Go to Site Administration > Actions > Runners
```

## Configuration

### Scaling Runners

To scale the number of runners, update the `replicaCount` in `runners-helm-release.yaml`:

```yaml
# Replica configuration for scaling
replicaCount: 3  # Change this number
```

Then reconcile:
```bash
flux reconcile kustomization flux-system --with-source
```

### Runner Labels

The runners are configured with these labels by default:
- `ubuntu-latest`
- `ubuntu-22.04`
- `self-hosted`

You can modify the labels in `runners-helm-release.yaml`:

```yaml
# Runner labels - these determine which jobs this runner can execute
labels: "ubuntu-latest,ubuntu-22.04,self-hosted,my-custom-label"
```

### Resource Limits

Current resource configuration:
- **CPU Limits**: 2000m (2 cores)
- **Memory Limits**: 4Gi
- **CPU Requests**: 1000m (1 core)
- **Memory Requests**: 2Gi

Adjust these in `runners-helm-release.yaml` based on your cluster capacity.

## Using Runners in Workflows

In your `.forgejo/workflows/*.yml` files, specify the runner:

```yaml
name: CI Pipeline
on: [push, pull_request]

jobs:
  build:
    runs-on: self-hosted  # or ubuntu-latest, ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: |
          echo "Building on self-hosted runner!"
          # Your build commands here
```

## Troubleshooting

### Runner Not Appearing in Forgejo

1. Check pod logs:
   ```bash
   kubectl logs -n forgejo -l app=act-runner
   ```

2. Verify the registration token is correct
3. Ensure Forgejo is accessible from the cluster
4. Check network policies aren't blocking access

### Runner Registration Failed

1. Verify the token hasn't expired (tokens have a limited lifetime)
2. Generate a new token if needed
3. Update the secret and re-encrypt:
   ```bash
   # Decrypt, edit, re-encrypt
   sops --decrypt secrets.yaml > temp-secrets.yaml
   # Edit temp-secrets.yaml with new token
   sops --encrypt temp-secrets.yaml > secrets.yaml
   rm temp-secrets.yaml
   ```

### Pod Stuck in Pending

1. Check resource availability:
   ```bash
   kubectl describe pod -n forgejo -l app=act-runner
   ```

2. Verify Longhorn storage is available:
   ```bash
   kubectl get pvc -n forgejo
   ```

## Security Considerations

- Runner tokens are stored encrypted with SOPS
- Runners have access to your cluster network
- Consider network policies to limit runner access
- Regularly rotate runner registration tokens
- Monitor runner usage and logs

## Alternative Deployment Methods

If you prefer not to use the vquie chart, you can also:

1. **Use the official Forgejo runner image directly** with a custom Deployment
2. **Use the gitea/act_runner chart** (compatible with Forgejo)
3. **Deploy runners on separate nodes** with node selectors

The current setup uses the `vquie/act-runner` chart which is well-maintained and works reliably with Forgejo.

## Files Overview

- `runners-helm-repository.yaml`: Defines the Helm repository for the act-runner chart
- `runners-helm-release.yaml`: Main configuration for the runners deployment
- `secrets.yaml`: Your existing encrypted secrets file (add RUNNER_TOKEN here)
- `RUNNERS_README.md`: This documentation file

## Support

For issues with:
- **FluxCD deployment**: Check FluxCD logs and this repository
- **Runner functionality**: Check the [vquie/helm-charts](https://github.com/vquie/helm-charts) repository
- **Forgejo Actions**: Check the [Forgejo documentation](https://forgejo.org/docs/latest/admin/actions/) 