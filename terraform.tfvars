# IMPORTANT — State Drift Notice
# Infrastructure was manually terminated in March 2026 outside of Terraform.
# Before next apply, run: terraform state list
# Remove any drifted resources with: terraform state rm <resource>
# Or run terraform apply — it will recreate missing resources cleanly.
# Update cluster_name below to avoid AWS naming conflicts on redeploy.

vpc_cidr_block       = "10.0.0.0/16"
private_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets_cidr  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

project_name       = "eks-platform"
kubernetes_version = "1.33"
aws_region         = "us-east-2"
environment        = "dev"

node_group_instance_types = ["t3.medium"]
node_group_min_size       = 1
node_group_max_size       = 5
node_group_desired_size = 1