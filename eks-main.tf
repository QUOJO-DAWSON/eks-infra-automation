provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "azs" {
  state = "available"
}

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr_block       = var.vpc_cidr_block
  private_subnets_cidr = var.private_subnets_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  availability_zones   = data.aws_availability_zones.azs.names
}

module "eks" {
  source = "./modules/eks"

  project_name              = var.project_name
  environment               = var.environment
  kubernetes_version        = var.kubernetes_version
  vpc_id                    = module.vpc.vpc_id
  private_subnets           = module.vpc.private_subnets
  admin_role_arn            = aws_iam_role.external-admin.arn
  developer_role_arn        = aws_iam_role.external-developer.arn
  node_group_instance_types = var.node_group_instance_types
  node_group_min_size       = var.node_group_min_size
  node_group_max_size       = var.node_group_max_size
  node_group_desired_size   = var.node_group_desired_size
}