# LibreChat

This directory provisions LibreChat via Flux straight from the official LibreChat GitHub repository (`https://github.com/danny-avila/LibreChat`). Flux pulls the chart sources from that repo and renders them with the values found here.

## Helm chart updates

- `git-repository.yaml` tracks the upstream LibreChat repo and exposes it to Flux under the `librechat` source.
- `helm-release.yaml` references the chart at `./helm/librechat` inside that Git source, so Flux always renders the exact chart committed by the LibreChat maintainers.
- Upstream chart updates land when you `just sync` or allow Flux to reconcile; it will fetch the latest `main` branch revision of the upstream repo.
- To lock to a specific tag or commit, adjust `spec.ref` in `git-repository.yaml` (for example, set `tag: chart-1.8.10`).
- Check which commit Flux is using with `flux get sources git librechat -n librechat` and the rendered release with `flux get helmreleases -n librechat`.

### Ingress note

The upstream chart can create its own Kubernetes Ingress, but this cluster uses Traefik `IngressRoute` resources instead. `values.ingress.enabled` is set to `false` in `helm-release.yaml` to avoid clashing routes (and the redirect loops they cause).

Secrets for API keys live in `secrets.yaml` and remain managed with SOPS.
