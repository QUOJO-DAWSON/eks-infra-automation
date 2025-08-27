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
├── terraform.tfvars                        # Variable values for deployment
└── variables.tf                            # Input variables for the module
```


## Deployment

The repository is configured with GitHub Actions workflows for automated deployment. The workflows follow this sequence:

1. **Bootstrap Backend**: Sets up the Terraform backend (S3 bucket with native state locking)
2. **Deploy Infrastructure**: Validates, plans, and applies the Terraform configuration
3. **Destroy Infrastructure**: Tears down the infrastructure when needed (requires the same variables as deployment)

### GitHub Actions Configuration

To use the GitHub Actions workflows, configure the following in your GitHub repository:

#### Required Secrets

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `ADMIN_USER_ARN` | ARN of the AWS user for admin role | Yes |
| `DEV_USER_ARN` | ARN of the AWS user for developer role | Yes |
| `ACTIONS_AWS_ROLE_ARN` | ARN of the AWS role that GitHub Actions will assume | Yes |
| `GITOPS_URL` | URL of the Git repository ArgoCD connects to and syncs | Optional* |
| `GITOPS_USERNAME` | Username for the Git repository | Optional* |
| `GITOPS_PASSWORD` | Password or token for the Git repository | Optional* |

*Required only if using ArgoCD with private Git repositories

#### Required Variables

| Variable Name | Description | Example |
|---------------|-------------|----------|
| `AWS_REGION` | AWS region for deployment | `us-east-1` |

#### Additional Requirements

- Configure AWS OIDC provider for GitHub Actions to assume roles without storing AWS credentials in GitHub

### GitHub Actions Workflows

| Workflow | Purpose | Trigger |
|----------|---------|----------|
| **Bootstrap Backend** (`bootstrap-backend.yaml`) | Sets up S3 bucket with DynamoDB table for Terraform state management and locking | Manual dispatch (`workflow_dispatch`) |
| **Deploy Infrastructure** (`deploy-infrastructure.yaml`) | Validates and plans on Pull Requests, applies infrastructure on push to `main` branch | Pull Request: Plan infrastructure, Push to `main`: Apply infrastructure |
| **Destroy Infrastructure** (`destroy-infrastructure.yaml`) | Tears down all infrastructure resources created by Terraform | Manual dispatch (`workflow_dispatch`) |

## Key Components

### EKS Cluster

The EKS cluster is configured with:
- Configurable Kubernetes version
- Managed node groups with configurable EC2 instance types
- Node autoscaling with configurable min/max/desired capacity
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

| Service | Port Forward Command | URL | Username | Password Command |
|---------|---------------------|-----|----------|------------------|
| ArgoCD | `kubectl port-forward -n argocd svc/argocd-server 8080:443` | https://localhost:8080 | `admin` | `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" \| base64 -d` |
| Prometheus | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090` | http://localhost:9090 | - | - |
| Grafana | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80` | http://localhost:3000 | `admin` | `kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" \| base64 -d` |
| AlertManager | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093` | http://localhost:9093 | - | - |

## Accessing the EKS Cluster

To access the EKS cluster, you need to assume the IAM roles created by Terraform:

1. **Configure AWS CLI with access entry user**
   ```bash
   # Configure AWS CLI with the specific user credentials from ADMIN_USER_ARN or DEV_USER_ARN
   # This user must exist in your AWS account and have permission to assume the external roles
   aws configure --profile admin
   # Enter Access Key ID and Secret Access Key for the user specified in ADMIN_USER_ARN
   ```

2. **Assume IAM role and export credentials**
   ```bash
   # Replace 123456789012 with your actual AWS account ID
   # Assume the external-admin role and capture output
   ROLE_OUTPUT=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/external-admin --role-session-name eks-access --profile admin)
   
   # Export temporary credentials (must be run in the same terminal session)
   export AWS_ACCESS_KEY_ID=$(echo $ROLE_OUTPUT | jq -r '.Credentials.AccessKeyId')
   export AWS_SECRET_ACCESS_KEY=$(echo $ROLE_OUTPUT | jq -r '.Credentials.SecretAccessKey')
   export AWS_SESSION_TOKEN=$(echo $ROLE_OUTPUT | jq -r '.Credentials.SessionToken')
   ```
   
   > **⚠️ Important**: These credentials are only valid in the current terminal session. All subsequent AWS commands must be run in the same terminal.

3. **Configure kubectl access**
   ```bash
   # Use the exported credentials to configure kubectl
   aws eks update-kubeconfig --region <your-aws-region> --name <your-cluster-name>
   ```

## Access Management

The cluster is configured with two access roles:
- Admin role: Full cluster admin access
- Developer role: View-only access to specific namespaces

## Variables

### Required Variables (GitHub Secrets)

| Variable | Description | Type |
|----------|-------------|------|
| `user_for_admin_role` | ARN of AWS user for admin role | string |
| `user_for_dev_role` | ARN of AWS user for developer role | string |

### Configuration Variables (terraform.tfvars)

| Variable | Description | Default Value | Type |
|----------|-------------|---------------|------|
| `aws_region` | AWS region for deployment | `us-east-1` | string |
| `project_name` | Project name prefix | `george-shop` | string |
| `kubernetes_version` | EKS cluster version | `1.33` | string |
| `environment` | Environment name | `dev` | string |
| `vpc_cidr_block` | CIDR block for VPC | `10.0.0.0/16` | string |
| `private_subnets_cidr` | CIDR blocks for private subnets | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | list(string) |
| `public_subnets_cidr` | CIDR blocks for public subnets | `["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]` | list(string) |
| `node_group_instance_types` | Instance types for EKS managed node group | `["t2.large"]` | list(string) |
| `node_group_min_size` | Minimum number of nodes | `1` | number |
| `node_group_max_size` | Maximum number of nodes | `5` | number |
| `node_group_desired_size` | Desired number of nodes | `2` | number |

## Related Projects

- **[Application Repository](https://github.com/iamfet/online-boutique-application)** - Microservices source code
- **[GitOps Repository](# EKS Infrastructure Automation

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
├── terraform.tfvars                        # Variable values for deployment
└── variables.tf                            # Input variables for the module
```

## Deployment

The repository is configured with GitHub Actions workflows for automated deployment. The workflows follow this sequence:

1. **Bootstrap Backend**: Sets up the Terraform backend (S3 bucket with native state locking)
2. **Deploy Infrastructure**: Validates, plans, and applies the Terraform configuration
3. **Destroy Infrastructure**: Tears down the infrastructure when needed (requires the same variables as deployment)

### GitHub Actions Configuration

To use the GitHub Actions workflows, configure the following in your GitHub repository:

#### Required Secrets

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `ADMIN_USER_ARN` | ARN of the AWS user for admin role | Yes |
| `DEV_USER_ARN` | ARN of the AWS user for developer role | Yes |
| `ACTIONS_AWS_ROLE_ARN` | ARN of the AWS role that GitHub Actions will assume | Yes |
| `GITOPS_URL` | URL of the Git repository ArgoCD connects to and syncs | Optional* |
| `GITOPS_USERNAME` | Username for the Git repository | Optional* |
| `GITOPS_PASSWORD` | Password or token for the Git repository | Optional* |

*Required only if using ArgoCD with private Git repositories

#### Required Variables

| Variable Name | Description | Example |
|---------------|-------------|----------|
| `AWS_REGION` | AWS region for deployment | `us-east-1` |

#### Additional Requirements

- Configure AWS OIDC provider for GitHub Actions to assume roles without storing AWS credentials in GitHub

### GitHub Actions Workflows

| Workflow | Purpose | Trigger |
|----------|---------|----------|
| **Bootstrap Backend** (`bootstrap-backend.yaml`) | Sets up S3 bucket with DynamoDB table for Terraform state management and locking | Manual dispatch (`workflow_dispatch`) |
| **Deploy Infrastructure** (`deploy-infrastructure.yaml`) | Validates and plans on Pull Requests, applies infrastructure on push to `main` branch | Pull Request: Plan infrastructure, Push to `main`: Apply infrastructure |
| **Destroy Infrastructure** (`destroy-infrastructure.yaml`) | Tears down all infrastructure resources created by Terraform | Manual dispatch (`workflow_dispatch`) |

## Key Components

### EKS Cluster

The EKS cluster is configured with:
- Configurable Kubernetes version
- Managed node groups with configurable EC2 instance types
- Node autoscaling with configurable min/max/desired capacity
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

| Service | Port Forward Command | URL | Username | Password Command |
|---------|---------------------|-----|----------|------------------|
| ArgoCD | `kubectl port-forward -n argocd svc/argocd-server 8080:443` | https://localhost:8080 | `admin` | `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" \| base64 -d` |
| Prometheus | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090` | http://localhost:9090 | - | - |
| Grafana | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80` | http://localhost:3000 | `admin` | `kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" \| base64 -d` |
| AlertManager | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093` | http://localhost:9093 | - | - |

## Accessing the EKS Cluster

To access the EKS cluster, you need to assume the IAM roles created by Terraform:

1. **Configure AWS CLI with access entry user**
   ```bash
   # Configure AWS CLI with the specific user credentials from ADMIN_USER_ARN or DEV_USER_ARN
   # This user must exist in your AWS account and have permission to assume the external roles
   aws configure --profile admin
   # Enter Access Key ID and Secret Access Key for the user specified in ADMIN_USER_ARN
   ```

2. **Assume IAM role and export credentials**
   ```bash
   # Replace 123456789012 with your actual AWS account ID
   # Assume the external-admin role and capture output
   ROLE_OUTPUT=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/external-admin --role-session-name eks-access --profile admin)
   
   # Export temporary credentials (must be run in the same terminal session)
   export AWS_ACCESS_KEY_ID=$(echo $ROLE_OUTPUT | jq -r '.Credentials.AccessKeyId')
   export AWS_SECRET_ACCESS_KEY=$(echo $ROLE_OUTPUT | jq -r '.Credentials.SecretAccessKey')
   export AWS_SESSION_TOKEN=$(echo $ROLE_OUTPUT | jq -r '.Credentials.SessionToken')
   ```
   
   > **⚠️ Important**: These credentials are only valid in the current terminal session. All subsequent AWS commands must be run in the same terminal.

3. **Configure kubectl access**
   ```bash
   # Use the exported credentials to configure kubectl
   aws eks update-kubeconfig --region <your-aws-region> --name <your-cluster-name>
   ```

## Access Management

The cluster is configured with two access roles:
- Admin role: Full cluster admin access
- Developer role: View-only access to specific namespaces

## Variables

### Required Variables (GitHub Secrets)

| Variable | Description | Type |
|----------|-------------|------|
| `user_for_admin_role` | ARN of AWS user for admin role | string |
| `user_for_dev_role` | ARN of AWS user for developer role | string |

### Configuration Variables (terraform.tfvars)

| Variable | Description | Default Value | Type |
|----------|-------------|---------------|------|
| `aws_region` | AWS region for deployment | `us-east-1` | string |
| `project_name` | Project name prefix | `george-shop` | string |
| `kubernetes_version` | EKS cluster version | `1.33` | string |
| `environment` | Environment name | `dev` | string |
| `vpc_cidr_block` | CIDR block for VPC | `10.0.0.0/16` | string |
| `private_subnets_cidr` | CIDR blocks for private subnets | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` | list(string) |
| `public_subnets_cidr` | CIDR blocks for public subnets | `["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]` | list(string) |
| `node_group_instance_types` | Instance types for EKS managed node group | `["t2.large"]` | list(string) |
| `node_group_min_size` | Minimum number of nodes | `1` | number |
| `node_group_max_size` | Maximum number of nodes | `5` | number |
| `node_group_desired_size` | Desired number of nodes | `2` | number |

## Related Projects

- **[Application Repository](https://github.com/QUOJO-DAWSON/online-boutique-application)** - Microservices source code
- **[GitOps Repository](https://github.com/QUOJO-DAWSON/online-boutique-gitops)** - Deployment configurations and manifests

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature-name`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some feature'`)
5. Push to the branch (`git push origin feature/your-feature-name`)
6. Submit a pull request

## License

See the [LICENSE](LICENSE) file for details.)** - Deployment configurations and manifests

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature-name`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some feature'`)
5. Push to the branch (`git push origin feature/your-feature-name`)
6. Submit a pull request

## License

See the [LICENSE](LICENSE) file for details.