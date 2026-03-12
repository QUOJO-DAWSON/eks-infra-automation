# ADR-004: Reliability Strategy — HPA and PodDisruptionBudgets

## Status
Accepted

## Date
2026-03-12

## Context

The platform runs two categories of workloads:

1. **Cluster add-ons** — ArgoCD, Kyverno, Prometheus, Grafana. Managed by Terraform via Helm releases in this repository.
2. **Application workloads** — Online Boutique microservices (11 services). Managed by ArgoCD from the online-boutique-gitops repository.

Both categories require availability guarantees during voluntary disruptions such as node drains, cluster upgrades, and autoscaling events. Without PodDisruptionBudgets, a node drain can terminate all replicas of a component simultaneously, causing outages.

Additionally, application workloads need horizontal scaling to handle variable traffic load without manual intervention.

## Decision

### PodDisruptionBudgets (this repository)

PDBs for cluster add-ons are managed as `kubernetes_manifest` resources in `reliability.tf`:

| Component | Namespace | minAvailable |
|-----------|-----------|--------------|
| argocd-server | argocd | 1 |
| argocd-repo-server | argocd | 1 |
| kyverno-admission-controller | kyverno | 1 |
| prometheus | monitoring | 1 |
| grafana | monitoring | 1 |

`minAvailable: 1` is chosen over `maxUnavailable` to provide an absolute guarantee regardless of replica count changes.

### HPA and Application PDBs (online-boutique-gitops repository)

HorizontalPodAutoscalers and PDBs for application workloads are defined as Kubernetes manifests in the gitops repository under `overlays/dev/reliability/`. This separation keeps application reliability concerns co-located with application deployment manifests.

HPA targets for Online Boutique services:

| Service | minReplicas | maxReplicas | CPU target |
|---------|-------------|-------------|------------|
| frontend | 2 | 10 | 70% |
| cartservice | 2 | 8 | 70% |
| checkoutservice | 2 | 8 | 70% |
| productcatalogservice | 2 | 6 | 70% |
| recommendationservice | 1 | 4 | 80% |
| paymentservice | 2 | 6 | 70% |
| shippingservice | 1 | 4 | 80% |
| emailservice | 1 | 4 | 80% |
| currencyservice | 1 | 4 | 80% |
| adservice | 1 | 4 | 80% |
| redis-cart | 1 | 1 | N/A |

All services with `minReplicas >= 2` also have a PDB with `minAvailable: 1`.

## Consequences

- Node drains during cluster upgrades will not cause complete outages for any critical component
- Application workloads automatically scale under load without manual intervention
- Metrics Server (already deployed) provides the CPU metrics required by HPA
- PDB configuration is version-controlled and applied consistently via GitOps and Terraform
- redis-cart is excluded from HPA as StatefulSet-style single-instance caching does not benefit from horizontal scaling