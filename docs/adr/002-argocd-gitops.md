# ADR-002: GitOps Delivery Model via ArgoCD

| Field       | Value                    |
|-------------|--------------------------|
| **Status**  | Accepted                 |
| **Date**    | 2024-10-08               |
| **Deciders**| Platform / Infrastructure team |

---

## Context

We need a deployment model for continuously delivering the Online Boutique application and cluster add-on resources to EKS. Two primary delivery patterns were evaluated:

- **Push-based CI/CD** — a GitHub Actions pipeline runs `kubectl apply` or `helm upgrade` directly after each commit.
- **Pull-based GitOps** — a controller running inside the cluster watches a Git repository and reconciles the desired state continuously.

---

## Decision

We will adopt **GitOps via ArgoCD** as the deployment model for all cluster workloads. ArgoCD is deployed through Terraform (Helm release) and manages two `Application` objects:

1. `cluster-resources` — cluster-scoped add-ons (namespaces, RBAC, network policies)
2. `online-boutique` — the Online Boutique microservices application

A dedicated **GitOps repository** (`online-boutique-gitops`) stores all Kubernetes manifests, keeping deployment configuration cleanly separated from both the infrastructure code (this repo) and the application source code (`online-boutique-application`).

---

## Alternatives Considered

### Push-based CI/CD (GitHub Actions `kubectl apply`)
- **Pros:** Simpler mental model; no in-cluster controller to maintain; straightforward audit log via GitHub Actions history.
- **Cons:** Requires storing `kubeconfig` or IAM credentials in GitHub Secrets for every pipeline; cluster state can drift from Git if someone applies changes manually; no continuous reconciliation — drift is only detected on the next pipeline run; difficult to manage rollbacks without custom scripting.

### Flux (GitOps Toolkit)
- **Pros:** CNCF graduated alongside ArgoCD; highly modular (separate controllers for each source type); native Helm and Kustomize support; lower memory footprint than ArgoCD.
- **Cons:** No web UI out of the box (requires separate tooling for visualisation); multi-tenancy model is more complex to configure; smaller community compared to ArgoCD in AWS-centric environments.

### ArgoCD (Selected)
- **Pros:** Rich web UI providing real-time sync status and application topology; ApplicationSet controller enables scalable multi-app patterns; first-class Kustomize + Helm support; robust RBAC model; extensive community and AWS EKS integration documentation; `argocd` CLI complements `kubectl` for operator workflows.
- **Cons:** Higher memory footprint (~200MB for the server component); ArgoCD RBAC configuration adds initial setup complexity; requires ArgoCD-specific manifests (`Application` CRDs) that create a soft vendor dependency.

---

## Rationale

GitOps was chosen over push-based delivery for three reasons:

1. **Drift detection and auto-remediation.** ArgoCD continuously reconciles live cluster state against the GitOps repo. Manual changes are flagged immediately and can be auto-corrected, enforcing Git as the single source of truth.

2. **Credential security.** The pull-based model means only ArgoCD (running inside the cluster with an in-cluster service account) needs access to the cluster. GitHub Actions no longer requires `kubeconfig` credentials stored as secrets.

3. **Auditability.** Every deployment is traceable to a Git commit in the GitOps repo, providing a clear audit trail that maps application version → deployment event → Git author.

ArgoCD was chosen over Flux because the visual application topology and sync status UI provides substantially better observability into deployment health during active development, which outweighs the marginal resource cost difference.

---

## Repository Separation Model

```
eks-infra-automation/          ← Infrastructure (this repo)
  Terraform, Helm releases, IAM, networking

online-boutique-application/   ← Application source
  Dockerfiles, service code, CI pipeline

online-boutique-gitops/        ← Desired state (ArgoCD watches this)
  Kubernetes manifests, Kustomize overlays, Helm values
```

This three-repo pattern maps cleanly to team boundaries: platform engineers own infra, developers own application, and the GitOps repo is the contract between them.

---

## Consequences

### Positive
- Cluster state is fully recoverable from Git — disaster recovery is a re-sync operation.
- Deployments are self-documenting through Git commit history.
- Rollback is `git revert` + sync, not a pipeline re-run.

### Negative
- ArgoCD introduces an additional operational component that must be monitored and upgraded.
- First-time setup requires bootstrapping ArgoCD before it can manage itself (handled via Terraform Helm release).
- Developers must understand the GitOps workflow: changes go to the gitops repo, not applied directly to the cluster.

### Mitigations
- ArgoCD is deployed via Terraform, making it reproducible and version-pinned.
- Prometheus `ServiceMonitor` scrapes ArgoCD metrics; Grafana dashboard tracks sync lag and error rates.
