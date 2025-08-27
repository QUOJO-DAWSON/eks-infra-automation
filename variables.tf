variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "private_subnets_cidr" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
}

variable "public_subnets_cidr" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes Version of the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region where the EKS cluster will be created"
  type        = string
}

variable "user_for_admin_role" {
  description = "ARN of AWS user for admin role"
  type        = string
  # No default value, set in github repo secrets
}

variable "user_for_dev_role" {
  description = "ARN of AWS user for developer role"
  type        = string
  # No default value, set in github repo secrets
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "node_group_instance_types" {
  description = "Instance types for EKS managed node group"
  type        = list(string)
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the EKS managed node group"
  type        = number
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the EKS managed node group"
  type        = number
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the EKS managed node group"
  type        = number
}

# If the git repository that ArgoCD syncs is private, these variables are required
#variable "gitops_url" {
#  description = "URL of git repo argocd connects and sync"
#  type        = string
#  # No default value
#}
#
#variable "gitops_username" {
#  description = "Username of git repo argocd connects and sync"
#  type        = string
#  # No default value
#}
#
#variable "gitops_password" {
#  description = "Password of git repo argocd connects and sync"
#  type        = string
#  # No default value
#}