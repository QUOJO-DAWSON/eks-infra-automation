# EKS Infrastructure Automation

> **Production-grade EKS platform** -- Terraform-automated Kubernetes cluster with Istio service mesh, ArgoCD GitOps delivery, Kyverno policy-as-code, Prometheus/Grafana/AlertManager observability, and GitHub Actions CI/CD with tfsec and Trivy security scanning. Deploys a full 11-service microservices workload ([Online Boutique](https://github.com/QUOJO-DAWSON/online-boutique-application)) across dev, staging, and prod environments in a reproducible, zero-manual-steps workflow.

[![Terraform](https://img.shields.io/badge/Terraform-v1.12%2B-7B42BC?logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/EKS-v1.33-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![Istio](https://img.shields.io/badge/Istio-Service%20Mesh-466BB0?logo=istio)](https://istio.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo)](https://argoproj.github.io/cd/)
[![Kyverno](https://img.shields.io/badge/Kyverno-Policy--as--Code-00A9E0)](https://kyverno.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Problem Statement

Managing Kubernetes at scale requires more than a working cluster. Teams need **consistent, auditable deployments** (GitOps), **zero-trust networking** between services (service mesh), **early visibility into regressions** (observability), **secrets that never touch Git** (external secrets management), and **policy guardrails that enforce security standards at admission time** (policy-as-code).

This repository delivers a **turn-key, opinionated EKS platform** that wires all five concerns together through Terraform, allowing teams to focus on application delivery rather than infrastructure plumbing. It targets the pattern used by platform engineering teams at mid-to-large companies -- where a single IaC repository stands up the full cluster and its operational tooling reproducibly.

---

## Key Metrics

| Metric | Value |
|--------|-------|
| Cluster provisioning time | ~12 minutes (cold, from `terraform apply`) |
| Full workload deployment | ~3 minutes post-cluster (ArgoCD initial sync) |
| Zero-downtime deployments | Yes -- ArgoCD rolling sync + Istio traffic shifting |
| Secrets in Git | 0 -- all secrets via AWS Secrets Manager + ESO |
| Manual kubectl steps | 0 -- full GitOps, cluster state is 100% declarative |
| Inter-service encryption | 100% mTLS via Istio (zero application code changes) |
| Terraform resources managed | ~90 across 14 `.tf` files |
| Kyverno policies enforced | 5 ClusterPolicies (privileged, root, host namespaces, latest tag, resource limits) |
| Environments | 3 -- dev, staging, prod via Kustomize overlays |

---

## Architecture

![Architecture Diagram](docs/img/architecture.svg)

### System Overview
```
Internet -> ALB -> Istio Gateway -> VirtualService -> Microservices (mTLS)
                                          |
GitHub Actions ---- Terraform ---- EKS Cluster
                                          |
GitOps Repo ---- ArgoCD --------- Workloads + Add-ons
                                          |
AWS Secrets Manager ---- ESO ---- Kubernetes Secrets
                                          |
Kyverno ---- Admission Webhook ---- Policy Enforcement
```

The cluster is structured in three logical layers:

**Platform layer** -- deployed by Terraform: VPC, EKS, IAM roles, Istio, ArgoCD, External Secrets Operator, Prometheus stack, Kyverno admission controller, Cluster Autoscaler, Metrics Server, AWS Load Balancer Controller, NetworkPolicies, PodDisruptionBudgets.

**GitOps layer** -- managed by ArgoCD: cluster resources (namespaces, RBAC) and the Online Boutique application across dev, staging, and prod environments, sourced from the [GitOps repo](https://github.com/QUOJO-DAWSON/online-boutique-gitops).

**Application layer** -- the Online Boutique: 11 polyglot microservices (Go, Python, Node.js, C#) communicating exclusively over mTLS within the Istio mesh, with HPA and PodDisruptionBudgets on all services.

---

## Architecture Decision Records

| ADR | Decision | Status |
|-----|----------|--------|
| [ADR-001](docs/adr/001-istio-service-mesh.md) | Istio chosen over Linkerd and Cilium for service mesh | Accepted |
| [ADR-002](docs/adr/002-argocd-gitops.md) | GitOps via ArgoCD over push-based CI/CD and Flux | Accepted |
| [ADR-003](docs/adr/003-external-secrets-operator.md) | External Secrets Operator + AWS Secrets Manager over Sealed Secrets | Accepted |
| [ADR-004](docs/adr/004-reliability-hpa-pdb.md) | HPA and PDB strategy for cluster add-ons and application workloads | Accepted |

---

## Repository Structure
```
eks-infra-automation/
|-- .github/workflows/
|   |-- bootstrap-backend.yaml              # S3 bucket + native state locking
|   |-- deploy-infrastructure.yaml          # tfsec + Trivy scan, plan on PR, apply on merge
|   `-- destroy-infrastructure.yaml         # Manual teardown
|-- argocd-apps/
|   |-- cluster-resources-argo-app.yaml
|   |-- online-boutique-argo-app.yaml       # dev environment
|   |-- online-boutique-staging-argo-app.yaml
|   `-- online-boutique-prod-argo-app.yaml
|-- backend/
|   |-- main.tf
|   `-- outputs.tf
|-- docs/
|   |-- adr/
|   |   |-- 001-istio-service-mesh.md
|   |   |-- 002-argocd-gitops.md
|   |   |-- 003-external-secrets-operator.md
|   |   `-- 004-reliability-hpa-pdb.md
|   |-- img/
|   |   `-- architecture.svg
|   `-- runbooks/
|       |-- istio-troubleshooting.md
|       |-- istio-fault-injection.md        # Chaos engineering -- 3 fault injection scenarios
|       `-- terraform-operations.md
|-- monitoring/
|   |-- prometheus-alerts.yaml              # 14 SLO alert rules across 5 groups
|   `-- grafana-dashboard.yaml              # 10-panel dashboard, auto-imported via ConfigMap
|-- argocd.tf
|-- aws-load-balancer-controller.tf
|-- cluster-autoscaler.tf
|-- eks-main.tf                             # EKS cluster + VPC
|-- external-secrets.tf
|-- iam-roles.tf
|-- istio.tf
|-- istio-gateway-values.yaml
|-- kube-resources.tf
|-- kyverno.tf                              # Kyverno admission controller
|-- kyverno-policies.tf                     # 5 ClusterPolicies (policy-as-code)
|-- metrics-server.tf
|-- network-policies.tf                     # Zero-trust NetworkPolicies for online-boutique
|-- prometheus.tf                           # Prometheus stack + AlertManager routing
|-- reliability.tf                          # PodDisruptionBudgets for cluster add-ons
|-- outputs.tf
|-- providers.tf
|-- terraform.tfvars
`-- variables.tf
```

---

## Security Posture

### CI/CD Security Scanning

The deployment pipeline runs two parallel security jobs before any Terraform plan is allowed to proceed:

- **tfsec** -- scans all Terraform files for infrastructure misconfigurations
- **Trivy** -- scans for IaC misconfigs (CRITICAL/HIGH) and hard-blocks on any detected secrets (`exit-code: 1`)

### Admission Control (Kyverno)

Five ClusterPolicies are enforced at admission time across the cluster:

| Policy | Action | Scope |
|--------|--------|-------|
| Disallow privileged containers | Enforce | Cluster-wide |
| Disallow host namespaces (PID/IPC/Network) | Enforce | Cluster-wide |
| Require non-root user | Enforce | online-boutique |
| Disallow latest image tag | Enforce | online-boutique |
| Require resource limits | Audit | online-boutique |

### Network Segmentation

Five NetworkPolicies enforce zero-trust L4 segmentation in the online-boutique namespace: default deny-all, allow intra-namespace, allow DNS egress, allow Istio control plane, allow Prometheus scrape.

---

## Observability

| Component | Purpose |
|-----------|---------|
| Prometheus | Metrics collection with 14 SLO alert rules across 5 groups |
| Grafana | 10-panel dashboard auto-imported via ConfigMap |
| AlertManager | Severity-based Slack routing (critical -> #alerts-critical, warning -> #alerts-warning) with inhibit rules |
| Istio telemetry | Per-service request rate, error rate, and latency (RED metrics) |

---

## Reliability

| Component | Mechanism |
|-----------|-----------|
| Cluster add-ons | PodDisruptionBudgets (ArgoCD, Kyverno, Prometheus, Grafana) |
| Application workloads | HPA (CPU-based, all 11 services) + PDBs (services with minReplicas >= 2) |
| Node autoscaling | Cluster Autoscaler (min 1, max 5 nodes) |
| Multi-env promotion | dev (1 replica) -> staging (2 replicas) -> prod (3 replicas) via Kustomize overlays |

---

## Tools and Technologies

### Infrastructure as Code

| Tool | Purpose |
|------|---------|
| Terraform v1.12+ | All AWS and Kubernetes resource provisioning |
| Helm | Kubernetes package management for add-ons |
| Kustomize | Multi-environment manifest customisation (dev/staging/prod) |

### AWS Services

| Service | Role |
|---------|------|
| Amazon EKS | Managed Kubernetes control plane (v1.33) |
| Amazon VPC | Multi-AZ networking (public + private subnets) |
| AWS IAM + IRSA | Least-privilege pod-level AWS access via OIDC |
| AWS ALB | External traffic ingress via Load Balancer Controller |
| AWS Secrets Manager | Centralised secrets store (ESO backend) |

### Kubernetes Platform

| Component | Role |
|-----------|------|
| Istio + Istio Gateway | mTLS, traffic management, ingress |
| ArgoCD | GitOps continuous delivery (dev/staging/prod apps) |
| Kyverno | Admission control -- policy-as-code enforcement |
| Prometheus + Grafana + AlertManager | Metrics, dashboards, Slack alert routing |
| External Secrets Operator | Secrets sync from AWS Secrets Manager |
| Cluster Autoscaler | Node group horizontal scaling |
| Metrics Server | HPA metrics provider |
| AWS Load Balancer Controller | ALB/NLB provisioning from Kubernetes |
| GitHub Actions | CI/CD pipeline -- tfsec + Trivy scanning, OIDC auth |

---

## Prerequisites

- AWS CLI configured with permissions to create EKS, VPC, IAM, and S3 resources
- Terraform v1.12.0 or later
- `kubectl` CLI
- `helm` CLI
- AWS account with OIDC provider configured for GitHub Actions

---

## Deployment

The repository ships three GitHub Actions workflows:

### Step 1 -- Bootstrap the Terraform Backend

Run the **Bootstrap Backend** workflow (`workflow_dispatch`) once per AWS account. This creates the S3 bucket with native state locking.

### Step 2 -- Deploy Infrastructure

Push to `main` or open a PR to trigger the **Deploy Infrastructure** workflow:

- **Pull Request** -- tfsec scan + Trivy scan + `terraform validate` + `terraform plan` (no apply)
- **Push to `main`** -- all scans pass, then `terraform apply`

### Step 3 -- Destroy Infrastructure

Run the **Destroy Infrastructure** workflow (`workflow_dispatch`) to tear everything down.

---

### GitHub Actions -- Required Secrets

| Secret | Description | Required |
|--------|-------------|----------|
| `ADMIN_USER_ARN` | ARN of the AWS IAM user granted cluster admin role | Yes |
| `DEV_USER_ARN` | ARN of the AWS IAM user granted developer (read-only) role | Yes |
| `ACTIONS_AWS_ROLE_ARN` | ARN of the IAM role GitHub Actions assumes via OIDC | Yes |
| `SLACK_WEBHOOK_URL` | Slack incoming webhook for AlertManager notifications | Yes |
| `GITOPS_URL` | GitOps repository URL (ArgoCD source) | If private repo |
| `GITOPS_USERNAME` | Git username for ArgoCD | If private repo |
| `GITOPS_PASSWORD` | Git token for ArgoCD | If private repo |

### GitHub Actions -- Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_REGION` | Target AWS region | `us-east-1` |

> **Security note:** GitHub Actions authenticates to AWS via OIDC (`AssumeRoleWithWebIdentity`). No AWS credentials are stored as GitHub Secrets.

---

## Configuration Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `project_name` | Resource name prefix | `eks-platform` |
| `kubernetes_version` | EKS version | `1.33` |
| `environment` | Environment tag | `dev` |
| `vpc_cidr_block` | VPC CIDR | `10.0.0.0/16` |
| `node_group_instance_types` | EC2 instance types | `["t3.large"]` |
| `node_group_min_size` | Minimum nodes | `1` |
| `node_group_max_size` | Maximum nodes | `5` |
| `node_group_desired_size` | Desired nodes | `2` |
| `slack_webhook_url` | Slack webhook for AlertManager | `""` |

---

## Accessing Cluster UIs

| Service | Port Forward | URL |
|---------|--------------|-----|
| ArgoCD | `kubectl port-forward -n argocd svc/argocd-server 8080:443` | https://localhost:8080 |
| Prometheus | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090` | http://localhost:9090 |
| Grafana | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80` | http://localhost:3000 |
| AlertManager | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093` | http://localhost:9093 |

---

## Accessing the Cluster
```bash
# 1. Assume the admin role
ROLE_OUTPUT=$(aws sts assume-role \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/external-admin \
  --role-session-name eks-access \
  --profile admin)

# 2. Export temporary credentials
export AWS_ACCESS_KEY_ID=$(echo $ROLE_OUTPUT | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $ROLE_OUTPUT | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $ROLE_OUTPUT | jq -r '.Credentials.SessionToken')

# 3. Configure kubectl
aws eks update-kubeconfig --region <REGION> --name <CLUSTER_NAME>
```

> These credentials are session-scoped. Run all subsequent commands in the same terminal.

---

## Related Repositories

| Repository | Purpose |
|------------|---------|
| [eks-infra-automation](https://github.com/QUOJO-DAWSON/eks-infra-automation) | This repo -- cluster infrastructure |
| [online-boutique-application](https://github.com/QUOJO-DAWSON/online-boutique-application) | Microservices source code + CI pipeline |
| [online-boutique-gitops](https://github.com/QUOJO-DAWSON/online-boutique-gitops) | Kubernetes manifests -- dev/staging/prod overlays |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

---

## License

[MIT](LICENSE)