# Istio Fault Injection Runbook

## Overview

This runbook covers chaos engineering using Istio's built-in fault injection capabilities. Fault injection tests how the Online Boutique application handles failure scenarios without requiring a separate chaos engineering tool.

Istio supports two fault types:
- **Delays** — inject latency to simulate slow upstream services or network congestion
- **Aborts** — inject HTTP errors to simulate service failures

## Prerequisites

- kubectl configured with cluster access
- Cluster running with Istio sidecar injection enabled in the `online-boutique` namespace
- Application deployed and healthy (`kubectl get pods -n online-boutique`)
- Baseline metrics visible in Grafana before starting any test

## Safety Rules

- Always run fault injection against a non-production environment
- Always define a percentage less than 100% to avoid complete service blackout
- Always set a short test window and clean up immediately after
- Monitor Grafana and AlertManager during all tests
- Keep a second terminal open ready to run the cleanup commands

---

## Test 1 — Latency Injection on productcatalogservice

Simulates a slow product catalog, which affects the frontend rendering time.

### Apply
```bash
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: productcatalogservice-fault
  namespace: online-boutique
spec:
  hosts:
    - productcatalogservice
  http:
    - fault:
        delay:
          percentage:
            value: 50
          fixedDelay: 3s
      route:
        - destination:
            host: productcatalogservice
EOF
```

### What to observe

- Frontend response time increases in Grafana (Istio Service Dashboard)
- `istio_request_duration_milliseconds` metric spikes for `productcatalogservice`
- No HTTP errors — service still responds, just slowly

### Cleanup
```bash
kubectl delete virtualservice productcatalogservice-fault -n online-boutique
```

---

## Test 2 — Abort Injection on recommendationservice

Simulates the recommendation engine returning HTTP 500 errors for 30% of requests.

### Apply
```bash
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: recommendationservice-fault
  namespace: online-boutique
spec:
  hosts:
    - recommendationservice
  http:
    - fault:
        abort:
          percentage:
            value: 30
          httpStatus: 500
      route:
        - destination:
            host: recommendationservice
EOF
```

### What to observe

- Frontend should degrade gracefully — the recommendations section may be empty but the page should still load
- `istio_requests_total` error rate increases in Grafana
- AlertManager may fire `HighErrorRate` alert if the error rate crosses the SLO threshold

### Cleanup
```bash
kubectl delete virtualservice recommendationservice-fault -n online-boutique
```

---

## Test 3 — Combined Latency and Abort on cartservice

Simulates a degraded cart service — 20% of requests fail with 503, and 30% of requests experience 2s latency.

### Apply
```bash
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: cartservice-fault
  namespace: online-boutique
spec:
  hosts:
    - cartservice
  http:
    - fault:
        delay:
          percentage:
            value: 30
          fixedDelay: 2s
        abort:
          percentage:
            value: 20
          httpStatus: 503
      route:
        - destination:
            host: cartservice
EOF
```

### What to observe

- Add-to-cart operations fail for a portion of users
- Checkout flow errors visible in frontend
- Both latency and error rate metrics spike in Grafana
- Istio Kiali graph (if deployed) shows red edges on cartservice

### Cleanup
```bash
kubectl delete virtualservice cartservice-fault -n online-boutique
```

---

## Verify No Faults Are Active

Run this at any time to confirm no fault injection VirtualServices are present:
```bash
kubectl get virtualservice -n online-boutique
```

A clean cluster should return `No resources found in online-boutique namespace.` or only show application VirtualServices without a `fault:` stanza.

---

## Interpreting Results

| Observation | Conclusion |
|-------------|------------|
| Frontend degrades gracefully, partial errors only | Good — application has resilience patterns |
| Frontend completely fails on partial downstream error | Bad — missing retry/timeout/fallback logic |
| AlertManager fires within expected SLO window | Good — observability stack is working |
| No alerts fire despite injected errors | Bad — alert thresholds or routing may be misconfigured |
| Latency stays flat despite injected delay | Check — VirtualService may not have applied correctly |

---

## Related Resources

- [Istio Fault Injection Docs](https://istio.io/latest/docs/tasks/traffic-management/fault-injection/)
- Prometheus alerts: `monitoring/prometheus-alerts.yaml`
- Grafana dashboard: `monitoring/grafana-dashboard.yaml`
- AlertManager config: `prometheus.tf`