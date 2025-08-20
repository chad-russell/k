# Qwen Code Context for `/Users/chadrussell/Code/k`

## Project Overview

This directory contains Kubernetes configuration files managed by [Flux](https://fluxcd.io/), likely for a personal or small-scale homelab environment. The structure is based on Kustomize, organizing resources into distinct directories for core infrastructure, applications, and services.

Key components managed by this repository include:
- **MetalLB**: For load balancing.
- **Longhorn**: For distributed block storage.
- **Capacitor**: (Likely a specific application or service).
- **Ingress Controller**: For routing external traffic, configured with Traefik.
- **PostgreSQL**: Managed via the CloudNativePG operator.
- **Applications**: Organized under the `apps` directory, potentially including `development`, `infra`, `media`, and `productivity` subcategories.

The `Justfile` provides convenient commands for interacting with the Flux deployment.

## Managing the Cluster (Flux Commands)

Use the `just` command with the recipes defined in the `Justfile` to manage the cluster state:

- `just status`: View the current status of all Flux resources.
- `just sync`: Trigger a reconciliation of the Flux `kustomization` with its source.
- `just reconcile`: Manually trigger a Flux reconciliation of the git source.
- `just suspend`: Suspend the main Flux kustomization.
- `just resume`: Resume the main Flux kustomization.

These commands wrap the underlying `flux` CLI tool.

## Project Structure

- `kustomization.yaml`: The main Kustomize file that ties together all resources.
- `Justfile`: Contains helpful `just` commands for cluster management.
- `flux-system/`: Core Flux configuration (likely contains the main Flux Kustomization custom resource).
- `metallb/`: Configuration for the MetalLB load balancer.
- `longhorn/`: Configuration for the Longhorn distributed storage system.
- `capacitor/`: Configuration for the 'capacitor' service.
- `ingress/`: Configuration for the Traefik ingress controller.
- `postgres/`: Configuration for PostgreSQL using the CloudNativePG operator.
- `apps/`: Directory containing application-specific Kustomize configurations.