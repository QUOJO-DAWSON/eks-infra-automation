# Environment
aws_region   = "us-east-2"
project_name = "eks-platform"
environment  = "dev"

# Kubernetes
kubernetes_version = "1.33"

# Networking
vpc_cidr_block       = "10.0.0.0/16"
private_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets_cidr  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# Node Group
node_group_instance_types = ["t3.medium"]
node_group_min_size       = 1
node_group_max_size       = 3
node_group_desired_size   = 1