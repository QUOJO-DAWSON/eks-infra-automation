# Changelog

All notable changes to this project are documented here.

---

## [v2.0.0] — March 2026 (Sprint 2)

### Added
- Kyverno 3.2.6 admission controller with five ClusterPolicies (disallow-privileged, disallow-host-namespaces, disallow-latest-tag, require-resource-limits, require-non-root-user)
- Zero-trust NetworkPolicies for online-boutique namespace (default-deny-all with explicit allow rules)
- AlertManager Slack routing with severity-based channels
- PodDisruptionBudgets for all critical services
- HPA manifests for all Online Boutique services
- Istio fault injection runbook
- Kustomize overlays for staging and prod environments
- ArgoCD ApplicationSet replacing individual Application manifests
- Phase 1.5 bootstrap step resolving Kyverno CRD race condition
- Pre-phase 2 cleanup step for stuck Helm releases
- Local IAM user EKS access entry
- ExternalSecret and ClusterSecretStore for AWS Secrets Manager integration
- Branch protection rule with required Terraform plan status check
- Destroy workflow with confirmation gate
- Sprint 2 verification screenshots in docs/screenshots/

### Fixed
- AWS free-tier EC2 instance type restriction resolved via AWS Organization
- Kyverno CRD race condition between Helm install and policy apply
- Kyverno disallow-host-namespaces blocking Prometheus node-exporter
- Stuck kube-prometheus-stack Helm release from failed prior run
- ExternalSecret pointing to wrong ClusterSecretStore name
- Malformed JSON in AWS Secrets Manager stripe-api-key secret

### Changed
- require-non-root-user policy set to Audit mode for upstream image compatibility
- disallow-host-namespaces policy updated with system namespace exclusions
- Terraform plan expanded to full config for accurate PR gate

---

## [v1.0.0] — August 2025 (Sprint 1)

### Added
- VPC with public and private subnets across 3 availability zones
- EKS 1.33 managed node group with KMS encryption
- OIDC-based IAM for GitHub Actions — zero stored credentials
- S3 backend with native state locking
- ArgoCD v3.1.0 Helm deployment
- Istio 1.26.2 base, istiod, and ingress gateway
- kube-prometheus-stack with Grafana and AlertManager
- AWS Load Balancer Controller with IRSA
- Cluster Autoscaler with IRSA
- External Secrets Operator with IRSA
- Metrics Server
- GitHub Actions CI/CD pipeline with tfsec and Trivy scanning
- Four-phase apply pipeline (security scan, validate/plan, apply)
