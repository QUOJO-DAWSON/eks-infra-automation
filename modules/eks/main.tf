module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.1"

  name               = "${var.project_name}-eks-cluster"
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  endpoint_public_access = true

  addons = {
    coredns                = {}
    eks-pod-identity-agent = { before_compute = true }
    kube-proxy             = {}
    vpc-cni                = { before_compute = true }
  }

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    admin = {
      principal_arn = var.admin_role_arn
      username      = "admin"
      type          = "STANDARD"
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
      principal_arn = var.developer_role_arn
      username      = "developer"
      type          = "STANDARD"
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
    ingress_15017 = {
      description                   = "Cluster API to Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
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