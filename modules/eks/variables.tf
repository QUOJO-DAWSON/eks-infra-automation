variable "project_name" {
  description = "Prefix applied to all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to deploy the cluster into."
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for worker nodes."
  type        = list(string)
}

variable "admin_role_arn" {
  description = "ARN of the IAM role granted cluster admin access."
  type        = string
}

variable "developer_role_arn" {
  description = "ARN of the IAM role granted developer read-only access."
  type        = string
}

variable "node_group_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
}

variable "node_group_min_size" {
  description = "Minimum number of nodes."
  type        = number
}

variable "node_group_max_size" {
  description = "Maximum number of nodes."
  type        = number
}

variable "node_group_desired_size" {
  description = "Desired number of nodes."
  type        = number
}