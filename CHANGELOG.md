# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-03-07

### Added
- Production-grade EKS cluster (v1.33) with managed node groups (t3.large, min:1, max:5)
- Multi-AZ VPC with public and private subnets across 3 availability zones
- Istio service mesh with mTLS enforcement across all services
- ArgoCD GitOps managing cluster-resources and Online Boutique application
- Prometheus + Grafana + AlertManager observability stack
- AWS Load Balancer Controller for ALB provisioning
- Cluster Autoscaler for automatic node scaling
- External Secrets Operator integrated with AWS Secrets Manager via IRSA
- Metrics Server for HPA metrics support
- GitHub Actions CI/CD  bootstrap, deploy, destroy workflows
- OIDC-based GitHub Actions auth  no stored AWS credentials
- tfsec static security scanning on every push and PR
- Terraform fmt check enforced in CI
- PR plan comments with collapsible plan output
- ADR-001: Istio over Linkerd and Cilium
- ADR-002: ArgoCD GitOps over push-based CI/CD
- ADR-003: External Secrets Operator over Sealed Secrets
- Runbook: Istio troubleshooting
- Runbook: Terraform operations
- Prometheus SLO alert rules  node, workload, Istio, ArgoCD, Cluster Autoscaler
- Grafana dashboard as code via ConfigMap (10 panels, auto-imported)
- Variable validation blocks with clear error messages on all Terraform inputs
- Expanded outputs.tf with configure_kubectl helper output
- Architecture diagram embedded in README
- Online Boutique (11 microservices) deployed via ArgoCD

### Security
- mTLS enforced across all inter-service traffic via Istio PeerAuthentication
- Least-privilege IAM via IRSA  pod-level AWS access only
- Zero secrets in Git  AWS Secrets Manager + External Secrets Operator
- GitHub Actions uses OIDC AssumeRoleWithWebIdentity
- sensitive = true on all IAM ARN Terraform variables

### Fixed
- Upgraded node instances from t2.large to t3.large
- Removed personal project_name value from terraform.tfvars

---

## [Unreleased]

### Planned
- Multi-environment support via Terraform workspaces
- Istio canary release workflow via VirtualService weight shifting
- AlertManager notification routing to Slack
- Terraform module extraction for reusability
