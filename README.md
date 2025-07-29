# EKS Infrastructure Automation

This repository contains Terraform code to automate the deployment of an Amazon EKS cluster with various add-ons and configurations for running containerized applications on AWS.

## Architecture Overview

The infrastructure includes:

- Amazon EKS cluster (v1.33) with managed node groups
- VPC with public and private subnets across multiple availability zones
- Service mesh with Istio and Istio Gateway
- GitOps with ArgoCD
- Various Kubernetes add-ons:
  - AWS Load Balancer Controller
  - Cluster Autoscaler
  - External Secrets Operator
  - Metrics Server
  - Prometheus monitoring stack with AlertManager and Grafana

## Features

- **EKS Cluster Provisioning**: Automated setup of an EKS cluster with best practices.
- **ArgoCD**: GitOps continuous delivery tool for Kubernetes.
- **AWS Load Balancer Controller**: Manages AWS Elastic Load Balancers for Kubernetes services.
- **Cluster Autoscaler**: Automatically adjusts the number of nodes in your cluster.
- **External Secrets**: Integrates Kubernetes with AWS Secrets Manager.
- **Istio**: Service mesh for traffic management, security, and observability.
- **Istio Gateway**: Ingress gateway for managing external traffic into the service mesh.
- **Metrics Server**: Resource usage metrics for Kubernetes.
- **Prometheus**: Monitoring and alerting toolkit with Grafana dashboards and AlertManager.
- **IAM Roles**: Fine-grained access control for Kubernetes workloads.

## Tools and Technologies Used

### Infrastructure as Code
- **Terraform**: For provisioning and managing AWS resources
- **Helm**: Package manager for Kubernetes
- **Kustomize**: Kubernetes configuration customization

### AWS Services
- **Amazon EKS**: Managed Kubernetes service
- **Amazon VPC**: Networking infrastructure
- **Amazon EC2**: Compute resources for EKS nodes
- **AWS IAM**: Identity and access management
- **AWS Load Balancer**: For exposing services
- **AWS Secrets Manager**: For managing secrets

### Kubernetes & DevOps
- **Kubernetes**: Container orchestration
- **ArgoCD**: GitOps continuous delivery
- **Istio**: Service mesh implementation with gateway
- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Visualization and dashboards
- **AlertManager**: Alert routing and notifications
- **GitHub Actions**: CI/CD pipeline

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform v1.12.0 or later
- kubectl command-line tool
- Helm package manager

## Repository Structure

```
eks-infra-automation/
├── .github/workflows/                      # GitHub Actions workflows for CI/CD
│   ├── bootstrap-backend.yaml              # Sets up S3 bucket with native state locking for Terraform state
│   ├── deploy-infrastructure.yaml          # Validates, plans, and applies Terraform configuration
│   └── destroy-infrastructure.yaml         # Tears down the infrastructure
├── argocd-apps/                            # ArgoCD application manifests
│   ├── cluster-resources-argo-app.yaml     # ArgoCD app for cluster resources
│   └── online-boutique-argo-app.yaml       # ArgoCD app for demo microservices
├── backend/                                # Terraform backend configuration
│   ├── main.tf                             # S3 backend with native state locking setup
│   └── outputs.tf                          # Backend outputs
├── argocd.tf                               # ArgoCD Helm deployment
├── aws-load-balancer-controller.tf         # AWS Load Balancer Controller deployment
├── cluster-autoscaler.tf                   # Cluster Autoscaler deployment
├── eks-main.tf                             # EKS cluster and VPC configuration
├── external-secrets.tf                     # External Secrets Operator deployment
├── iam-roles.tf                            # IAM roles for cluster access
├── istio-gateway-values.yaml               # Istio gateway configuration values
├── istio.tf                                # Istio service mesh and gateway deployment
├── kube-resources.tf                       # Kubernetes resources configuration
├── metrics-server.tf                       # Metrics Server deployment
├── prometheus.tf                           # Prometheus monitoring stack deployment
├── outputs.tf                              # Terraform outputs
├── providers.tf                            # Provider configurations
└── variables.tf                            # Input variables for the module
```

## Deployment

### Automated Deployment (GitHub Actions)

The repository is configured with GitHub Actions workflows for automated deployment. The workflows follow this sequence:

1. **Bootstrap Backend**: Sets up the Terraform backend (S3 bucket with native state locking)
2. **Deploy Infrastructure**: Validates, plans, and applies the Terraform configuration
3. **Destroy Infrastructure**: Tears down the infrastructure when needed (requires the same variables as deployment)

#### GitHub Actions Configuration

To use the GitHub Actions workflows, you need to configure the following in your GitHub repository:

1. **Secrets**:
   - `ADMIN_USER_ARN`: ARN of the AWS user for admin role
   - `DEV_USER_ARN`: ARN of the AWS user for developer role
   - `ACTIONS_AWS_ROLE_ARN`: ARN of the AWS role that GitHub Actions will assume

   If using ArgoCD with private Git repositories, also add:
   - `GITOPS_URL`: URL of the Git repository ArgoCD connects to and syncs
   - `GITOPS_USERNAME`: Username for the Git repository
   - `GITOPS_PASSWORD`: Password or token for the Git repository
   
   These secrets are passed as variables to Terraform in the GitHub Actions workflow like this:
   ```yaml
   terraform plan -out=tfplan \
     -var="user_for_admin_role=${{ secrets.ADMIN_USER_ARN }}" \
     -var="user_for_dev_role=${{ secrets.DEV_USER_ARN }}" \
     -var="gitops_url=${{ secrets.GITOPS_URL }}" \
     -var="gitops_username=${{ secrets.GITOPS_USERNAME }}" \
     -var="gitops_password=${{ secrets.GITOPS_PASSWORD }}"
   ```

2. **Variables**:
   - `AWS_REGION`: AWS region for deployment (e.g., `us-east-1`)

3. **AWS OIDC Configuration**:
   - Configure AWS OIDC provider for GitHub Actions to assume roles without storing AWS credentials in GitHub

### Manual Deployment

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var="user_for_admin_role=<admin-user-arn>" -var="user_for_dev_role=<dev-user-arn>"

# Apply the configuration
terraform apply -var="user_for_admin_role=<admin-user-arn>" -var="user_for_dev_role=<dev-user-arn>"

# Destroy the infrastructure (when needed)
terraform destroy -var="user_for_admin_role=<admin-user-arn>" -var="user_for_dev_role=<dev-user-arn>"
```

## Key Components

### EKS Cluster

The EKS cluster is configured with:
- Kubernetes version 1.33
- Managed node groups with t2.large EC2 instances
- Node autoscaling from 2 to 5 nodes based on workload
- IAM roles for secure cluster access

### Service Mesh

Istio is deployed as the service mesh solution with:
- Base CRDs and components
- Control plane (istiod)
- Data plane (ingress gateway)

### Monitoring and Observability

Prometheus stack is deployed with:
- Prometheus server for metrics collection and observability
- Grafana for visualization and dashboards
- AlertManager for alert routing and notifications
- ServiceMonitors for automatic service discovery

### GitOps

ArgoCD is configured to manage:
- Cluster resources
- Online Boutique application (demo microservices application)

> **Note**: The repository includes commented code for configuring ArgoCD with private Git repositories. If you need to use private repositories, uncomment the relevant sections in `argocd.tf` and `variables.tf`, and provide the required secrets in GitHub Actions. These variables will be passed to Terraform through the GitHub Actions workflow.

## Accessing Web UIs

### ArgoCD

**Get ArgoCD admin password:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Access ArgoCD UI:**
```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```
Then visit: `https://localhost:8080`
- Username: `admin`
- Password: Use the password retrieved above

### Prometheus

**Access Prometheus UI:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```
Then visit: `http://localhost:9090`

### Grafana

**Get Grafana admin password:**
```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d
```

**Access Grafana UI:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```
Then visit: `http://localhost:3000`
- Username: `admin`
- Password: Use the password retrieved above

### AlertManager

**Access AlertManager UI:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093
```
Then visit: `http://localhost:9093`

## Access Management

The cluster is configured with two access roles:
- Admin role: Full cluster admin access
- Developer role: View-only access to specific namespaces

## Variables

The following variables can be customized to configure your deployment:

### Required Variables

- **user_for_admin_role**: ARN of AWS user for admin role
- **user_for_dev_role**: ARN of AWS user for developer role

### Optional Variables with Defaults

- **aws_region**: AWS region for deployment
  - Default: `us-east-1`

- **project_name**: Project name prefix
  - Default: `george-shop`

- **cluster_version**: EKS cluster version
  - Default: `1.33`

- **vpc_cidr_block**: CIDR block for VPC
  - Default: `10.0.0.0/16`

- **private_subnets_cidr**: CIDR blocks for private subnets
  - Default: `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]`

- **public_subnets_cidr**: CIDR blocks for public subnets
  - Default: `["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]`

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature-name`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some feature'`)
5. Push to the branch (`git push origin feature/your-feature-name`)
6. Submit a pull request

## License

See the [LICENSE](LICENSE) file for details.