# Runbook: Istio Troubleshooting

| Field | Value |
|-------|-------|
| **Component** | Istio Service Mesh |
| **Namespace** | `istio-system` |
| **Last Updated** | 2024-10-15 |

---

## Quick Reference — Common Symptoms

| Symptom | Most Likely Cause | Jump To |
|---------|-------------------|---------|
| 503 errors between services | mTLS policy mismatch | [§ mTLS Issues](#mtls-policy-issues) |
| Pod stuck in `Init` state | Sidecar injection failing | [§ Sidecar Injection](#sidecar-injection-issues) |
| Traffic not reaching service | VirtualService misconfiguration | [§ Traffic Routing](#traffic-routing-issues) |
| `upstream connect error` | Circuit breaker open or destination unreachable | [§ Circuit Breaker](#circuit-breaker--connection-issues) |
| Istio Gateway returning 404 | Gateway/VirtualService host mismatch | [§ Gateway Issues](#gateway-issues) |
| High memory on nodes | Sidecar resource limits not set | [§ Resource Issues](#resource-issues) |

---

## Prerequisites

```bash
# Verify istioctl is installed
istioctl version

# Verify Istio control plane is healthy
kubectl get pods -n istio-system

# Expected output — all pods Running:
# istiod-xxxxx           1/1   Running
# istio-ingressgateway   1/1   Running
```

---

## Diagnostic — Cluster-Wide Health Check

Run this first for any Istio issue. It catches ~80% of misconfigurations:

```bash
istioctl analyze --all-namespaces
```

Look for `Error` and `Warning` lines. Common output:

```
Warning [IST0102] Namespace default is not labeled for Istio injection.
Error   [IST0101] VirtualService references host "svc-x" not found in namespace "default".
```

---

## mTLS Policy Issues

**Symptoms:** `RBAC: access denied`, `upstream connect error`, 503 between services.

### Step 1 — Check mTLS mode for the namespace

```bash
kubectl get peerauthentication -A
kubectl get destinationrule -A
```

### Step 2 — Verify mTLS is working between two services

```bash
# Check effective mTLS policy between source and destination
istioctl authn tls-check <source-pod> <destination-service>.<namespace>.svc.cluster.local
```

Expected output when healthy:
```
HOST:PORT                          STATUS     SERVER     CLIENT
svc-x.default.svc.cluster.local   OK         STRICT     ISTIO_MUTUAL
```

### Step 3 — Check AuthorizationPolicy

```bash
kubectl get authorizationpolicy -A
kubectl describe authorizationpolicy <name> -n <namespace>
```

### Fix — Namespace mTLS mismatch

If one service is in `STRICT` mode and the other is in `PERMISSIVE`, traffic will be rejected:

```yaml
# Apply PERMISSIVE mode temporarily to isolate the issue
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: <affected-namespace>
spec:
  mtls:
    mode: PERMISSIVE
```

> **Note:** Revert to `STRICT` once the root cause is resolved.

---

## Sidecar Injection Issues

**Symptoms:** Pod starts but only has 1 container (missing Envoy sidecar), `Init:0/1` state.

### Step 1 — Check namespace label

```bash
kubectl get namespace <namespace> --show-labels
# Must have: istio-injection=enabled
```

If missing:
```bash
kubectl label namespace <namespace> istio-injection=enabled
# Restart pods to pick up sidecar injection
kubectl rollout restart deployment -n <namespace>
```

### Step 2 — Check pod-level injection override

```bash
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.metadata.annotations}'
# Look for: sidecar.istio.io/inject: "false"
```

### Step 3 — Check istiod logs

```bash
kubectl logs -n istio-system -l app=istiod --tail=100 | grep -i error
```

### Step 4 — Verify webhook configuration

```bash
kubectl get mutatingwebhookconfiguration istio-sidecar-injector -o yaml | grep -A5 namespaceSelector
```

---

## Traffic Routing Issues

**Symptoms:** Requests going to wrong version, canary not working, unexpected 404s.

### Step 1 — Inspect VirtualService and DestinationRule

```bash
kubectl get virtualservice -A
kubectl get destinationrule -A
kubectl describe virtualservice <name> -n <namespace>
```

### Step 2 — Check proxy config for a specific pod

```bash
# View the Envoy config for a running pod
istioctl proxy-config routes <pod-name>.<namespace>
istioctl proxy-config clusters <pod-name>.<namespace>
istioctl proxy-config endpoints <pod-name>.<namespace>
```

### Step 3 — Verify service endpoints are registered

```bash
istioctl proxy-config endpoints <pod-name>.<namespace> | grep <service-name>
# If no endpoints listed, the service has no healthy pods
```

### Fix — VirtualService host mismatch

The `host` in a VirtualService must exactly match the Kubernetes Service name:

```yaml
# WRONG
spec:
  hosts:
  - my-service.default    # missing .svc.cluster.local or short name

# CORRECT
spec:
  hosts:
  - my-service            # short name works within same namespace
  # or
  - my-service.default.svc.cluster.local
```

---

## Gateway Issues

**Symptoms:** External traffic returning 404, Gateway not routing to services.

### Step 1 — Verify Gateway and VirtualService are linked

```bash
kubectl get gateway -A
kubectl describe gateway <name> -n <namespace>
```

The VirtualService must reference the gateway by name:
```yaml
spec:
  gateways:
  - istio-system/istio-ingressgateway   # namespace/gateway-name
```

### Step 2 — Check ingress gateway pod logs

```bash
kubectl logs -n istio-system -l app=istio-ingressgateway --tail=100
```

### Step 3 — Verify ALB is pointing to the gateway

```bash
kubectl get svc istio-ingressgateway -n istio-system
# Check EXTERNAL-IP — should show ALB DNS name
```

### Step 4 — Test routing from inside the cluster

```bash
# Bypass external ingress to isolate whether the issue is ALB or Istio
kubectl run debug --image=curlimages/curl -it --rm -- \
  curl http://istio-ingressgateway.istio-system.svc.cluster.local/
```

---

## Circuit Breaker / Connection Issues

**Symptoms:** `upstream connect error or disconnect/reset before headers`, intermittent 503s.

### Step 1 — Check DestinationRule outlier detection settings

```bash
kubectl describe destinationrule <name> -n <namespace>
# Look for outlierDetection block
```

### Step 2 — Check if hosts are being ejected

```bash
istioctl proxy-config endpoints <pod-name>.<namespace> | grep -i ejected
```

### Step 3 — Review Envoy access logs

```bash
# Enable access logging if not already on
kubectl logs <pod-name> -n <namespace> -c istio-proxy --tail=200
```

Look for `UO` (upstream overflow) or `UF` (upstream connection failure) response flags.

---

## Resource Issues

**Symptoms:** Node memory pressure, OOMKilled sidecars.

### Check sidecar resource consumption

```bash
kubectl top pods -A --containers | grep istio-proxy | sort -k4 -rn | head -20
```

### Set sidecar resource limits via annotation

```yaml
metadata:
  annotations:
    sidecar.istio.io/proxyCPU: "100m"
    sidecar.istio.io/proxyMemory: "128Mi"
    sidecar.istio.io/proxyCPULimit: "200m"
    sidecar.istio.io/proxyMemoryLimit: "256Mi"
```

---

## Useful One-Liners

```bash
# Full mesh status overview
istioctl proxy-status

# Check all Envoy listeners for a pod
istioctl proxy-config listeners <pod>.<namespace>

# Dump full Envoy config for deep debugging
istioctl proxy-config all <pod>.<namespace> -o json > envoy-dump.json

# Watch Istio access logs in real-time
kubectl logs -n istio-system -l app=istio-ingressgateway -f

# Check if mTLS is enforced cluster-wide
kubectl get peerauthentication -A

# Restart istiod (last resort, non-destructive)
kubectl rollout restart deployment/istiod -n istio-system
```

---

## Escalation Path

If the above steps do not resolve the issue:

1. Capture `istioctl analyze --all-namespaces` output
2. Capture `istioctl proxy-status` output
3. Dump Envoy config for the affected pod: `istioctl proxy-config all <pod>.<ns> -o json`
4. Check istiod logs: `kubectl logs -n istio-system -l app=istiod --tail=500`
5. Open issue with the above outputs attached
