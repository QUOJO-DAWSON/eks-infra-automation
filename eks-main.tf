provider "aws" {
  region = var.aws_region
}

#VPC for Cluster
data "aws_availability_zones" "azs" {
  state = "available"
} #queries AWS to provide the names of availability zones dynamically

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

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
    Terraform                                               = "true"
    Environment                                             = var.environment
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

#EKS for Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.1"

  name               = "${var.project_name}-eks-cluster"
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  endpoint_public_access = true

  addons = {
    coredns                = {}
    eks-pod-identity-agent = { before_compute = true }
    kube-proxy             = {}
    vpc-cni                = { before_compute = true }
  }

  # Set authentication mode to API
  authentication_mode = "API"

  # Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  # Add access entries
  access_entries = {
    admin = {
      principal_arn = aws_iam_role.external-admin.arn
      username      = "admin"
      type          = "STANDARD"

      # Grant admin access with admin access-policy
      policy_associations = {
        viewer = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    developer = {
      principal_arn = aws_iam_role.external-developer.arn
      username      = "developer"
      type          = "STANDARD"

      # Grant developer access with view-only permissions to specific namespace
      policy_associations = {
        viewer = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["online-boutique"]
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    dev = {
      instance_types = var.node_group_instance_types
      min_size       = var.node_group_min_size
      max_size       = var.node_group_max_size
      desired_size   = var.node_group_desired_size
      tags = {
        "k8s.io/cluster-autoscaler/enabled"                         = "true"
        "k8s.io/cluster-autoscaler/${var.project_name}-eks-cluster" = "owned"
      }
    }
  }

  node_security_group_additional_rules = {

    #Enables automatic sidecar injection when pods are created
    ingress_15017 = {
      description                   = "Cluster API to Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }

    #Enables service discovery and configuration distribution
    ingress_15012 = {
      description                   = "Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  tags = {
    environment = var.environment
    terraform   = true
  }

}