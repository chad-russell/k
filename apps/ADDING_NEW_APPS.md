# Adding New Apps to the Kubernetes Cluster

This guide outlines the process and patterns for adding new applications to this Kubernetes cluster using Kustomize and Flux.

## Directory Structure

The apps are organized in a hierarchical structure:
```
apps/
├── category/
│   ├── app-name/
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml (if needed)
│   │   ├── deployment.yaml OR helm-release.yaml
│   │   ├── ingress.yaml
│   │   └── ... (other resources)
│   └── kustomization.yaml
└── kustomization.yaml
```

## Categories

Apps are grouped into categories based on their purpose:
- `development` - Development tools and services
- `fun` - Entertainment and recreational apps
- `infra` - Infrastructure services
- `media` - Media management and streaming services
- `productivity` - Productivity and utility apps

## App Directory Structure

Each app should have its own directory within the appropriate category. The directory should contain:

1. `kustomization.yaml` - References all resources for the app
2. Resource files:
   - `namespace.yaml` - Creates a dedicated namespace for the app (if needed)
   - `deployment.yaml` - For standard Kubernetes deployments (or)
   - `helm-release.yaml` - For Helm chart deployments
   - `ingress.yaml` - Configures external access to the app
   - Other optional resources (configmaps, secrets, etc.)

## Kustomization Files

### Root kustomization.yaml
The root `apps/kustomization.yaml` should reference each category directory:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - development/
  - infra/
  - media/
  - productivity/
  - fun/
```

### Category kustomization.yaml
Each category's `kustomization.yaml` should reference each app directory:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - app1/
  - app2/
  - app3/
```

### App kustomization.yaml
Each app's `kustomization.yaml` should reference all resources for that app:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace.yaml    # If creating a dedicated namespace
  - deployment.yaml   # Or helm-release.yaml for Helm deployments
  - ingress.yaml
```

## Resource Types

### Namespace
If the app requires a dedicated namespace, create a `namespace.yaml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: app-name
```

### Helm Releases
For apps deployed via Helm charts, use a `helm-release.yaml`:
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: app-name
  namespace: app-namespace
spec:
  interval: 15m
  chart:
    spec:
      chart: chart-name
      version: "chart-version"
      sourceRef:
        kind: HelmRepository
        name: repository-name
        namespace: app-namespace
      interval: 15m
  values:
    # Chart-specific values
```

If using a Helm repository, also include a `helm-repository.yaml`:
```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: repository-name
  namespace: app-namespace
spec:
  interval: 1h
  type: oci  # or other type
  url: oci://repository-url
```

### Standard Deployments
For apps deployed with standard Kubernetes manifests, use a `deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-name
  namespace: app-namespace
  labels:
    app: app-name
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-name
  template:
    metadata:
      labels:
        app: app-name
    spec:
      containers:
        - name: app-name
          image: image-repository:image-tag
          ports:
            - containerPort: port-number
          env:
            - name: ENV_VAR
              value: "value"
          volumeMounts:
            - name: data-volume
              mountPath: /data
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "1Gi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: port-number
            initialDelaySeconds: 60
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /health
              port: port-number
            initialDelaySeconds: 30
            periodSeconds: 10
      volumes:
        - name: data-volume
          persistentVolumeClaim:
            claimName: data-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: app-namespace
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: Service
metadata:
  name: app-name
  namespace: app-namespace
  labels:
    app: app-name
spec:
  ports:
    - port: service-port
      targetPort: container-port
  selector:
    app: app-name
```

### Ingress
All externally accessible apps should have an `ingress.yaml` using Traefik:
```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: app-name
  namespace: app-namespace
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`app-name.domain.com`)
      kind: Rule
      services:
        - name: app-name
          port: service-port
  tls:
    certResolver: letsencrypt
```

## Best Practices

1. **Namespace Isolation**: Create a dedicated namespace for each app when possible
2. **Resource Limits**: Always specify resource requests and limits for containers
3. **Health Checks**: Implement both liveness and readiness probes
4. **Persistent Storage**: Use Longhorn for persistent storage when needed
5. **Security**: Drop unnecessary capabilities and run as non-root where possible
6. **Environment Variables**: Use appropriate environment variables for configuration
7. **Naming Consistency**: Keep names consistent across resources (deployment, service, ingress)

## Adding a New App

1. Create a new directory in the appropriate category: `apps/category/app-name/`
2. Create the required resource files based on the app type (Helm or standard deployment)
3. Create a `kustomization.yaml` in the app directory referencing all resources
4. Add the app to the category's `kustomization.yaml`
5. Test the deployment locally with `kubectl kustomize`
6. Commit and push the changes to trigger Flux deployment