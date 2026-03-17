# online-boutique-gitops

> GitOps repository for the Online Boutique microservices application. Managed by ArgoCD, deployed to the EKS platform provisioned in [eks-infra-automation](https://github.com/QUOJO-DAWSON/eks-infra-automation).

---

## What This Is

This repo is the application-side of a two-repo GitOps architecture. It contains the Kubernetes manifests and Kustomize overlays for the Online Boutique — an 11-service e-commerce microservices application — deployed to a production-grade EKS cluster.

This repo owns **what gets deployed**. The platform repo owns **where it runs**.

ArgoCD watches this repository and automatically syncs any changes to the cluster. No manual `kubectl apply` commands. No pipeline that touches the cluster directly. The Git commit is the deployment.

---

## Platform

This application runs on the EKS platform defined in:

**[eks-infra-automation](https://github.com/QUOJO-DAWSON/eks-infra-automation)** — Terraform-managed EKS cluster with Istio, Kyverno, Prometheus/Grafana, External Secrets Operator, AWS Load Balancer Controller, and Cluster Autoscaler.

If you are looking for how the cluster is provisioned, how ArgoCD is installed, or how the security policies are defined — that is the repo to look at.

---

## Architecture
```
developer pushes to this repo
          │
          ▼
    GitHub (source of truth)
          │
          │ ArgoCD polls every 3 minutes
          ▼
    ArgoCD (running in-cluster)
          │
          │ applies manifests
          ▼
    online-boutique namespace (EKS)
          │
          ├── 11 microservice Deployments
          ├── Services
          ├── HorizontalPodAutoscalers
          ├── PodDisruptionBudgets
          ├── NetworkPolicies
          ├── VirtualService (Istio)
          └── ExternalSecret (→ AWS Secrets Manager)
```

---

## Repository Structure
```
online-boutique-gitops/
├── base/
│   ├── adservice.yaml
│   ├── cartservice.yaml
│   ├── checkoutservice.yaml
│   ├── currencyservice.yaml
│   ├── emailservice.yaml
│   ├── frontend.yaml
│   ├── paymentservice.yaml
│   ├── productcatalogservice.yaml
│   ├── recommendationservice.yaml
│   ├── redis.yaml
│   ├── shippingservice.yaml
│   └── kustomization.yaml
├── app-config/
│   ├── externalsecret.yaml     # Pulls Stripe API key from AWS Secrets Manager
│   ├── virtual-service.yaml    # Istio routing for frontend
│   ├── hpa.yaml                # HPA for all services
│   ├── pdb.yaml                # PodDisruptionBudgets
│   ├── network-policies.yaml   # Default-deny + explicit allow rules
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml  # Dev image tags + patches
    │   └── reliability.yaml    # Dev-specific reliability config
    ├── staging/
    │   └── kustomization.yaml  # Staging overrides
    └── prod/
        └── kustomization.yaml  # Production overrides
```

---

## Services

| Service | Language | Role |
|---------|----------|------|
| frontend | Go | User-facing UI, exposed via Istio VirtualService |
| cartservice | C# | Shopping cart, backed by Redis |
| productcatalogservice | Go | Product listings |
| currencyservice | Node.js | Currency conversion |
| paymentservice | Node.js | Payment processing (uses Stripe secret) |
| orderingservice | Go | Order orchestration |
| checkoutservice | Go | Checkout flow |
| emailservice | Python | Order confirmation emails |
| recommendationservice | Python | Product recommendations |
| adservice | Java | Ad serving |
| redis-cart | Redis | Cart data store |

---

## Reliability

Every service is configured with:

**HorizontalPodAutoscaler** — scales on CPU utilisation. High-traffic services (frontend, cartservice, checkoutservice) have higher max replicas and lower CPU thresholds.

**PodDisruptionBudget** — ensures at least 1 replica of each service remains available during node drains or cluster upgrades. Prevents cascading failures during maintenance windows.

---

## Security

**NetworkPolicies** — the `online-boutique` namespace runs under a default-deny-all policy. Traffic is only permitted via explicit allow rules:
- Intra-namespace pod-to-pod communication
- Istio control plane (istiod) communication
- Prometheus scraping (port 9090, 15090)
- DNS egress (port 53 UDP/TCP to kube-system)

**Kyverno policies** (enforced by the platform) apply to all workloads in this namespace:
- No privileged containers
- No host namespaces (hostPID, hostIPC, hostNetwork)
- No `latest` image tags
- Resource limits required (audit)
- Non-root user required (audit — upstream images run as root)

**External Secrets** — the Stripe API key is never stored in this repo or in CI. The `ExternalSecret` resource instructs the External Secrets Operator to pull from AWS Secrets Manager at runtime, creating a Kubernetes secret the paymentservice consumes.

---

## Environments

| Environment | Path | Status |
|-------------|------|--------|
| dev | `overlays/dev` | ✅ Active — synced by ArgoCD |
| staging | `overlays/staging` | Overlay complete |
| prod | `overlays/prod` | Overlay complete |

The dev overlay is the active environment. Staging and prod overlays are structured and ready — promoting to those environments requires applying the corresponding ArgoCD Application manifest.

---

## Images

All service images are built from the upstream Google microservices-demo source and pushed to Docker Hub under `dawsonkesson/`. Image tags follow the GitHub Actions run ID convention (e.g. `v16319814565`) — no `latest` tags, ever.

---

## How to Deploy

ArgoCD handles deployment automatically on every push. To apply manually for a new environment:
```bash
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: online-boutique-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/QUOJO-DAWSON/online-boutique-gitops
    targetRevision: HEAD
    path: overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: online-boutique
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
```

---

## Screenshots

| What | Screenshot |
|------|-----------|
| ArgoCD — Online Boutique Healthy | ![ArgoCD Healthy](https://github.com/QUOJO-DAWSON/eks-infra-automation/raw/main/docs/screenshots/05-argocd-online-boutique-healthy.png) |
| ArgoCD — Full Resource Tree | ![ArgoCD Tree](https://github.com/QUOJO-DAWSON/eks-infra-automation/raw/main/docs/screenshots/06-argocd-resource-tree.png) |

> Screenshots are stored in the platform repo at [eks-infra-automation/docs/screenshots](https://github.com/QUOJO-DAWSON/eks-infra-automation/tree/main/docs/screenshots)

---

## Author

**George Dawson-Kesson** — AWS Certified Solutions Architect – Associate  
Portfolio: [gdawsonkesson.com](https://gdawsonkesson.com)  
GitHub: [QUOJO-DAWSON](https://github.com/QUOJO-DAWSON)  
Platform repo: [eks-infra-automation](https://github.com/QUOJO-DAWSON/eks-infra-automation)
