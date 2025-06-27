# Forgejo Actions Workflows

This directory contains Forgejo Actions workflows for automating GitOps operations with Flux.

## 📁 Workflows

### 1. `test-runner.yml` - Runner Testing
**Purpose**: Verify that your Forgejo Actions runner is working properly

**Triggers**:
- Manual dispatch (workflow_dispatch)
- Push to `.forgejo/workflows/**` files

**What it does**:
- Tests basic runner functionality
- Checks system information
- Verifies Kubernetes access
- Checks Flux CLI availability
- Tests Docker access

### 2. `flux.yml` - Basic Flux Operations
**Purpose**: Simple Flux GitOps automation

**Triggers**:
- Push to `main` branch → Automatic reconciliation
- Pull requests → Validation checks
- Manual dispatch → Flexible operations

**Features**:
- ✅ Automatic reconciliation on push to main
- ✅ Validation checks on pull requests
- ✅ Manual operations via workflow dispatch
- ✅ Status reporting

### 3. `flux-advanced.yml` - Advanced Flux Operations
**Purpose**: Comprehensive GitOps automation with SOPS support

**Triggers**:
- Push to `main` branch (specific paths only)
- Pull requests (specific paths only)
- Manual dispatch with advanced options

**Features**:
- ✅ Path-based triggering (only runs when relevant files change)
- ✅ SOPS encrypted secrets validation
- ✅ Comprehensive manifest validation
- ✅ Advanced reconciliation strategies
- ✅ Health checks and monitoring
- ✅ Dry-run capabilities

## 🚀 Usage

### Testing Your Runner
1. Go to your Forgejo repository
2. Navigate to **Actions**
3. Select **Test Runner** workflow
4. Click **Run workflow**
5. Check the logs to verify everything is working

### Automatic GitOps
- **Push to main**: Automatically triggers deployment
- **Create PR**: Automatically validates changes
- **Manual operations**: Use workflow dispatch for custom actions

### Manual Flux Operations
1. Go to **Actions** → **Advanced Flux GitOps**
2. Click **Run workflow**
3. Choose your action:
   - `reconcile-all`: Reconcile all resources
   - `reconcile-apps`: Reconcile only applications
   - `reconcile-infra`: Reconcile infrastructure
   - `check-health`: Health check
   - `force-sync`: Force synchronization
   - `get-status`: Get comprehensive status
4. Optionally enable dry-run mode
5. Click **Run workflow**

## 🔧 Customization

### Adding New Paths
To monitor additional directories, edit the `paths` section in the workflows:

```yaml
paths:
- 'apps/**'
- 'your-new-directory/**'
```

### Adding New Actions
To add custom Flux operations, extend the `case` statement in the manual operations:

```bash
case "${{ github.event.inputs.action }}" in
  your-action)
    echo "Running your custom action..."
    # Your commands here
    ;;
esac
```

### Environment Variables
Set environment variables at the workflow level:

```yaml
env:
  FLUX_SYSTEM_NAMESPACE: flux-system
  YOUR_CUSTOM_VAR: value
```

## 🔍 Monitoring

### Workflow Status
- Check workflow runs in the **Actions** tab
- Review logs for detailed information
- Monitor job status and duration

### Flux Status
The workflows provide comprehensive status reporting:
- Kustomization status
- HelmRelease status
- Pod health checks
- Recent events

## 🔒 Security Considerations

### SOPS Integration
- Workflows validate SOPS encrypted files
- Secrets are never exposed in logs
- Decryption happens securely on the runner

### Runner Security
- Uses `self-hosted` runners (your own infrastructure)
- No secrets leave your environment
- Full control over the execution environment

## 🐛 Troubleshooting

### Common Issues

1. **kubectl not found**
   - Ensure kubectl is installed on your runner
   - Check that the runner has cluster access

2. **Flux CLI not found**
   - The workflows automatically install Flux CLI
   - Check internet connectivity on the runner

3. **SOPS decryption fails**
   - Verify SOPS keys are properly configured
   - Check that the runner has access to decryption keys

4. **Workflow doesn't trigger**
   - Check the `paths` configuration
   - Verify branch protection rules
   - Ensure the workflow file syntax is correct

### Debugging
- Enable debug logging by adding `ACTIONS_STEP_DEBUG: true` to env
- Check runner logs: `kubectl logs -n forgejo -l app=act-runner -f`
- Review Flux status: `flux get all`

## 📚 Additional Resources

- [Forgejo Actions Documentation](https://forgejo.org/docs/latest/user/actions/)
- [Flux Documentation](https://fluxcd.io/docs/)
- [SOPS Documentation](https://github.com/mozilla/sops) 