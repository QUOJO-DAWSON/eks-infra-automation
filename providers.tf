terraform {
  backend "s3" {
    bucket       = "tf-state-eks-infra-271758791081"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
    /*dynamodb_table = "terraform-eks-state-locks"*/
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}
