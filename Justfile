# Justfile for managing Flux updates

# List all available recipes if no arguments are given.
default:
    just --list

reconcile:
    # Manually trigger a Flux reconciliation
    flux reconcile source git flux-system

sync:
    # Sync Flux with source
    flux reconcile kustomization flux-system --with-source

status:
    # Get Flux status
    flux get all

suspend:
    # Suspend Flux kustomization
    flux suspend kustomization flux-system

resume:
    # Resume Flux kustomization
    flux resume kustomization flux-system
