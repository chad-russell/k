# Qdrant Vector Database

This directory contains the Kubernetes manifests for deploying Qdrant, a vector database for the next generation of AI applications.

## Overview

Qdrant is a vector similarity search engine and vector database that provides fast and scalable vector storage and retrieval. It's particularly useful for AI applications that need to perform similarity searches on high-dimensional vector data.

## Deployment

The deployment uses the official Qdrant Helm chart from https://qdrant.github.io/qdrant-helm.

### Components

- `namespace.yaml`: Creates the `qdrant-system` namespace
- `helm-repository.yaml`: Defines the Qdrant Helm repository
- `helm-release.yaml`: Configures and deploys Qdrant using the Helm chart
- `ingress.yaml`: Exposes the Qdrant REST API and web UI at `qdrant.internal.crussell.io`

### Configuration

The deployment is configured with:
- 3 replicas for high availability
- Longhorn storage for persistence
- Cluster mode enabled for distributed operation
- Resource limits and requests appropriate for a vector database

## Access

The Qdrant service will be available:
- Within the cluster at `qdrant.qdrant-system.svc.cluster.local` on ports:
  - 6333 for REST API
  - 6334 for gRPC API
- Externally (with valid certificate) at `https://qdrant.internal.crussell.io`

## Scaling

To scale the deployment, modify the `replicas` value in `helm-release.yaml`. Note that Qdrant requires a StatefulSet for proper clustering, so scaling may require careful consideration of data distribution.

## Monitoring

Qdrant exposes metrics at the `/metrics` endpoint on port 6333.