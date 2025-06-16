# Karakeep - Bookmark Manager

Karakeep is a self-hosted bookmark manager with AI-powered tagging and full-text search capabilities.

## Architecture

This deployment includes three main components:

- **Karakeep App**: Main web application (port 3000)
- **Meilisearch**: Dedicated search engine for full-text search (port 7700)  
- **Chrome**: Headless browser for web scraping and screenshots (port 9222)

## Setup Instructions

### 1. Generate Secrets

Before deploying, generate random secrets:

```bash
# Generate secrets
echo "nextauth-secret: $(openssl rand -base64 36)"
echo "meili-master-key: $(openssl rand -base64 36)"
```

### 2. Update Secrets File

Edit the secrets file with your generated values:

```bash
# Edit the secrets (will be encrypted automatically)
sops apps/karakeep/secrets.yaml
```

Update the placeholder values with your generated secrets. Optionally add your OpenAI API key for AI-powered tagging.

### 3. Deploy

The app will be deployed automatically via GitOps:

```bash
git add apps/karakeep/
git commit -m "Add Karakeep bookmark manager"
git push
```

### 4. Access

Once deployed, access Karakeep at: https://karakeep.internal.crussell.io

## Storage

- **Karakeep Data**: 10Gi for bookmarks, screenshots, and cached content
- **Meilisearch Data**: 5Gi for search indexes

Both use Longhorn storage for persistence and backup.

## Resource Usage

- **Karakeep**: 512Mi-2Gi RAM, 200m-1000m CPU
- **Meilisearch**: 256Mi-1Gi RAM, 100m-500m CPU  
- **Chrome**: 256Mi-512Mi RAM, 100m-300m CPU

## Features

- 📚 Bookmark management with tags and collections
- 🔍 Full-text search across all saved content
- 📸 Automatic screenshots of web pages
- 🤖 AI-powered automatic tagging (with OpenAI API)
- 📱 Mobile apps and browser extensions
- 🗄️ Archive full web pages for offline access

## Optional: AI Tagging

To enable AI-powered automatic tagging:

1. Get an OpenAI API key from https://platform.openai.com/
2. Add it to the secrets file:
   ```bash
   sops apps/karakeep/secrets.yaml
   ```
3. Uncomment the `OPENAI_API_KEY` environment variable in `deployment.yaml`
4. Redeploy

## Monitoring

Check deployment status:

```bash
# Check all pods
kubectl get pods -n karakeep

# Check services
kubectl get svc -n karakeep

# Check ingress
kubectl get ingress -n karakeep

# View logs
kubectl logs -n karakeep deployment/karakeep
kubectl logs -n karakeep deployment/meilisearch
kubectl logs -n karakeep deployment/chrome
```

## Troubleshooting

### Common Issues

1. **Karakeep won't start**: Check that secrets are properly set
2. **Search not working**: Verify Meilisearch is running and accessible
3. **Screenshots failing**: Check Chrome container logs and resource limits
4. **Slow performance**: Consider increasing resource limits

### Useful Commands

```bash
# Port forward for local access
kubectl port-forward -n karakeep svc/karakeep 3000:3000

# Access Meilisearch directly (for debugging)
kubectl port-forward -n karakeep svc/meilisearch 7700:7700

# Restart deployments
kubectl rollout restart -n karakeep deployment/karakeep
kubectl rollout restart -n karakeep deployment/meilisearch
kubectl rollout restart -n karakeep deployment/chrome
``` 