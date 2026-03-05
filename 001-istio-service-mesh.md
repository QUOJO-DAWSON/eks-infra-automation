# ADR-001: Istio as the Service Mesh Solution

| Field       | Value                    |
|-------------|--------------------------|
| **Status**  | Accepted                 |
| **Date**    | 2024-10-01               |
| **Deciders**| Platform / Infrastructure team |

---

## Context

The EKS cluster hosts the Online Boutique — an 11-service polyglot microservices application (Go, Python, Node.js, C#). Without a service mesh, addressing the following cross-cutting concerns requires per-service implementation work:

- **Mutual TLS** between services (zero-trust networking)
- **Traffic management** — canary releases, circuit breaking, retries, timeouts
- **Observability** — distributed tracing, per-service metrics, traffic topology
- **Access policy enforcement** — which services may communicate with which

We evaluated three candidate service mesh solutions: **Istio**, **Linkerd**, and **Cilium Service Mesh**.

---

## Decision

We will deploy **Istio** (via the Helm-based install using `istio/base`, `istiod`, and `istio-ingressgateway` charts) managed through Terraform.

---

## Alternatives Considered

### Linkerd
- **Pros:** Lightweight (~50MB control plane), extremely simple installation, excellent Rust-based proxy performance, CNCF graduated project.
- **Cons:** Limited traffic management capabilities (no weighted routing in stable release at time of evaluation), no built-in gateway API support, smaller ecosystem for AWS-specific integrations.

### Cilium Service Mesh (eBPF-based)
- **Pros:** eBPF kernel-level enforcement eliminates sidecar overhead, best raw performance, doubles as CNI.
- **Cons:** Requires kernel 5.4+, significantly more complex to operate, limited mTLS policy expressiveness compared to Istio, less mature service mesh tooling in 2024.

### Istio (Selected)
- **Pros:** Industry-standard; CNCF graduated; richest traffic management API (VirtualService, DestinationRule, AuthorizationPolicy); native Prometheus metrics export via Envoy; AWS ALB integration via Gateway API; large operator community and extensive runbook corpus.
- **Cons:** Sidecar injection adds ~50ms to pod startup; control plane (`istiod`) consumes ~500MB RAM; upgrade cadence requires careful planning.

---

## Rationale

Istio was selected because the primary requirements — **mTLS enforcement, canary routing capability, and Prometheus-native observability** — align directly with its feature set. The operational overhead is justified given:

1. The demo workload (Online Boutique) explicitly tests service-to-service traffic policies.
2. Istio's `VirtualService` and `DestinationRule` allow traffic-shifting without application code changes.
3. Envoy sidecar metrics integrate automatically with the kube-prometheus-stack already deployed.
4. Istio's AWS ALB integration (via `istio-ingressgateway`) eliminates the need for a separate Nginx ingress controller.

---

## Consequences

### Positive
- All inter-service traffic is mTLS encrypted by default with zero application changes.
- Distributed traces (via Jaeger/Zipkin integration) are available without instrumenting application code.
- Canary releases and blue/green deployments can be executed through `VirtualService` weight adjustments.

### Negative
- Each pod requires an injected Envoy sidecar, increasing memory consumption by ~60MB per pod.
- Istio upgrade path (especially across minor versions) must follow the documented canary upgrade procedure.
- Debugging mTLS policy failures requires familiarity with `istioctl analyze` and `AuthorizationPolicy` semantics.

### Mitigations
- Resource limits are defined on sidecar containers to prevent memory bloat.
- Cluster Autoscaler compensates for increased per-pod resource requirements.
- Runbook (`docs/runbooks/istio-troubleshooting.md`) documents common failure modes.
