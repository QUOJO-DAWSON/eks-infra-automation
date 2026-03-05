# ── Cluster ───────────────────────────────────────────────────────────────────

output "cluster_name" {
  description = "Name of the EKS cluster. Used by CI/CD to configure kubectl and by monitoring for cluster identification."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "API server endpoint for the EKS cluster. Required for kubectl and in-cluster tooling configuration."
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version running on the EKS cluster."
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the EKS cluster. Required for kubectl authentication."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

# ── Networking ────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the VPC hosting the EKS cluster."
  value       = module.eks.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets where EKS worker nodes are provisioned."
  value       = module.eks.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets hosting the NAT Gateways and ALB."
  value       = module.eks.public_subnets
}

# ── Access ────────────────────────────────────────────────────────────────────

output "configure_kubectl" {
  description = "Run this command to configure kubectl access to the cluster after assuming the admin IAM role."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "node_group_role_arn" {
  description = "IAM role ARN assigned to the EKS managed node group."
  value       = module.eks.eks_managed_node_groups["eks_nodes"].iam_role_arn
}
