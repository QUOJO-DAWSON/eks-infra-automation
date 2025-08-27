vpc_cidr_block       = "10.0.0.0/16"
private_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets_cidr  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

project_name       = "george-shop"
kubernetes_version = "1.33"
aws_region         = "us-east-1"
environment        = "dev"

node_group_instance_types = ["t2.large"]
node_group_min_size       = 1
node_group_max_size       = 5
node_group_desired_size   = 2