variable "aws_region" {
  description = "AWS region where the EKS cluster and all associated resources will be provisioned."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region (e.g. us-east-1, eu-west-2)."
  }
}

variable "project_name" {
  description = "Prefix applied to all resource names for identification and cost allocation tagging."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,24}$", var.project_name))
    error_message = "project_name must be lowercase alphanumeric with hyphens, 3-25 characters, starting with a letter."
  }
}

variable "environment" {
  description = "Deployment environment. Used for resource tagging and namespace segregation."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Must be a supported version. Upgrades must be sequential (no skipping minor versions)."
  type        = string

  validation {
    condition     = can(regex("^1\\.[0-9]{2}$", var.kubernetes_version))
    error_message = "kubernetes_version must be in the format 1.XX (e.g. 1.33)."
  }
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC. Must be a valid IPv4 CIDR. Recommendation: /16 for sufficient subnet space."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr_block))
    error_message = "vpc_cidr_block must be a valid IPv4 CIDR block (e.g. 10.0.0.0/16)."
  }
}

variable "private_subnets_cidr" {
  description = "CIDR blocks for private subnets (one per AZ). EKS worker nodes run in private subnets."
  type        = list(string)

  validation {
    condition     = length(var.private_subnets_cidr) >= 2
    error_message = "At least 2 private subnets are required for EKS high availability across AZs."
  }
}

variable "public_subnets_cidr" {
  description = "CIDR blocks for public subnets (one per AZ). Used for NAT Gateways and the ALB ingress."
  type        = list(string)

  validation {
    condition     = length(var.public_subnets_cidr) >= 2
    error_message = "At least 2 public subnets are required for ALB and NAT Gateway high availability."
  }
}

# ── Node Group ────────────────────────────────────────────────────────────────

variable "node_group_instance_types" {
  description = "EC2 instance types for the EKS managed node group. Recommendation: t3.large or m5.large for production workloads."
  type        = list(string)

  validation {
    condition     = length(var.node_group_instance_types) > 0
    error_message = "At least one instance type must be specified for the node group."
  }
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the managed node group. Cluster Autoscaler will not scale below this value."
  type        = number

  validation {
    condition     = var.node_group_min_size >= 1
    error_message = "node_group_min_size must be at least 1 to ensure cluster availability."
  }
}

variable "node_group_max_size" {
  description = "Maximum number of nodes the Cluster Autoscaler can scale up to."
  type        = number

  validation {
    condition     = var.node_group_max_size >= var.node_group_min_size
    error_message = "node_group_max_size must be greater than or equal to node_group_min_size."
  }
}

variable "node_group_desired_size" {
  description = "Initial desired number of nodes. Cluster Autoscaler will adjust this based on workload demand."
  type        = number

  validation {
    condition     = var.node_group_desired_size >= var.node_group_min_size && var.node_group_desired_size <= var.node_group_max_size
    error_message = "node_group_desired_size must be between node_group_min_size and node_group_max_size."
  }
}

# ── Access Control ────────────────────────────────────────────────────────────

variable "user_for_admin_role" {
  description = "ARN of the IAM user granted cluster admin access via the external-admin IAM role. Passed via GitHub Actions secret ADMIN_USER_ARN."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:user/.+$", var.user_for_admin_role))
    error_message = "user_for_admin_role must be a valid IAM user ARN (arn:aws:iam::<account-id>:user/<username>)."
  }
}

variable "user_for_dev_role" {
  description = "ARN of the IAM user granted developer read-only access via the external-dev IAM role. Passed via GitHub Actions secret DEV_USER_ARN."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:user/.+$", var.user_for_dev_role))
    error_message = "user_for_dev_role must be a valid IAM user ARN (arn:aws:iam::<account-id>:user/<username>)."
  }
}

# ── GitOps (optional — required only for private ArgoCD repositories) ─────────

# Uncomment the following variables if ArgoCD connects to a private Git repository.
# Provide values via GitHub Actions secrets: GITOPS_URL, GITOPS_USERNAME, GITOPS_PASSWORD.

#variable "gitops_url" {
#  description = "HTTPS URL of the private Git repository ArgoCD monitors for workload manifests."
#  type        = string
#  sensitive   = true
#}
#
#variable "gitops_username" {
#  description = "Username for authenticating to the private GitOps repository."
#  type        = string
#  sensitive   = true
#}
#
#variable "gitops_password" {
#  description = "Personal access token or password for authenticating to the private GitOps repository."
#  type        = string
#  sensitive   = true
#}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL for AlertManager notifications"
  type        = string
  sensitive   = true
  default     = ""
}
