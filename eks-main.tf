provider "aws" {
  region = var.aws_region
}

#VPC for Cluster
data "aws_availability_zones" "azs" {
  state = "available"
} #queries AWS to provide the names of availability zones dynamically

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name            = "${var.project_name}-vpc"
  cidr            = var.vpc_cidr_block
  private_subnets = var.private_subnets_cidr
  public_subnets  = var.public_subnets_cidr
  azs             = data.aws_availability_zones.azs.names

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared" # Tags required for EKS to discover subnets
    environment = "development"
    application = "${var.project_name}"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                                = 1 # Identifies this subnet for external load balancers
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"                       = 1 # Identifies this subnet for internal services
  }

}