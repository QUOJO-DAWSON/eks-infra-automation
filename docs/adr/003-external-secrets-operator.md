# ADR-003: External Secrets Operator over Sealed Secrets

| Field       | Value                    |
|-------------|--------------------------|
| **Status**  | Accepted                 |
| **Date**    | 2024-10-15               |
| **Deciders**| Platform / Infrastructure team |

---

## Context

Kubernetes `Secret` objects are base64-encoded by default — not encrypted. Storing raw secrets in Git is a hard security violation. We need a strategy for:

1. Safely managing secrets referenced by workloads running in EKS.
2. Keeping secrets out of Git while remaining compatible with our GitOps model.
3. Leveraging AWS-native services we already pay for and operate.

Three approaches were evaluated: **AWS Secrets Manager + External Secrets Operator (ESO)**, **Bitnami Sealed Secrets**, and **HashiCorp Vault**.

---

## Decision

We will use **External Secrets Operator (ESO)** with **AWS Secrets Manager** as the secrets backend.

ESO is deployed via Terraform (Helm release). A `ClusterSecretStore` is configured with an IAM role (IRSA) scoped to read from Secrets Manager. Individual workloads reference secrets via `ExternalSecret` resources that specify the Secrets Manager path and the target Kubernetes `Secret` to create.

---

## Alternatives Considered

### Sealed Secrets (Bitnami)
- **Pros:** Entirely in-cluster solution; secrets are encrypted asymmetrically and safe to commit to Git; simple `kubeseal` CLI workflow; no dependency on external cloud services.
- **Cons:** Encrypted secrets are cluster-specific (re-encryption required if cluster is rebuilt); key rotation requires re-sealing every secret; no centralised secret versioning or audit trail; secrets are still materialised as Kubernetes `Secret` objects accessible to `kubectl get secret`.

### HashiCorp Vault
- **Pros:** Best-in-class secrets management; dynamic credentials; fine-grained audit logging; vendor-neutral and cloud-agnostic.
- **Cons:** Vault is a significant operational dependency — it requires HA setup, auto-unseal configuration, backup strategy, and its own monitoring; substantially higher total cost of ownership for a project that runs on AWS and already has Secrets Manager available.

### External Secrets Operator + AWS Secrets Manager (Selected)
- **Pros:** Secrets live in AWS Secrets Manager (encrypted at rest with KMS, full audit trail via CloudTrail, versioning built-in); ESO syncs them into the cluster as native `Secret` objects — zero application changes required; IRSA scoping means only the pods that need a secret get an IAM role that can read it; compatible with GitOps — `ExternalSecret` CRDs are safe to commit (they contain no secret material, only references); AWS Console / CLI can manage secrets without Kubernetes access.
- **Cons:** Runtime dependency on AWS API — if ESO cannot reach Secrets Manager, secret refresh fails (mitigated by `refreshInterval` and cached values in existing `Secret` objects); slightly more infrastructure surface area than Sealed Secrets.

---

## Rationale

Given the project already runs entirely on AWS, **AWS Secrets Manager is the natural secrets backend**. The audit trail (CloudTrail), automatic rotation support, versioning, and KMS encryption at rest are all available without additional infrastructure. ESO provides the bridge between Secrets Manager and Kubernetes without requiring application-level AWS SDK calls.

Sealed Secrets was ruled out primarily because its cluster-binding makes disaster recovery harder — rebuilding the cluster requires re-sealing every secret. ESO + Secrets Manager avoids this: the secrets live outside the cluster and are re-synced automatically on cluster rebuild.

Vault was ruled out as operationally disproportionate for a single-cluster project.

---

## Implementation Detail

```hcl
# external-secrets.tf (abbreviated)
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  namespace  = "external-secrets"
  ...
}
```

IAM trust policy uses IRSA (OIDC) — ESO's service account is the only principal that can call `secretsmanager:GetSecretValue` for the relevant secret ARNs. No long-lived credentials are stored anywhere in the cluster.

---

## Consequences

### Positive
- No secret material ever stored in Git, in the cluster's etcd (beyond the ephemeral synced `Secret`), or in environment variables baked into images.
- Secrets rotation in AWS Secrets Manager automatically propagates to pods within one `refreshInterval` cycle.
- Full read audit trail available in CloudTrail without any additional tooling.

### Negative
- Pods that require secrets have a startup dependency on AWS API availability.
- `ExternalSecret` CRD must be available before workloads that reference it can sync — ordering is managed via ArgoCD sync waves.

### Mitigations
- `refreshInterval` is set conservatively (1h) to avoid Secrets Manager API throttling.
- ESO caches the last successful secret value in the `Secret` object, so temporary Secrets Manager unavailability does not cause running pods to lose access to their secrets.
- ArgoCD sync wave ordering (`argocd.argoproj.io/sync-wave`) ensures ESO is healthy before dependent applications are synced.
