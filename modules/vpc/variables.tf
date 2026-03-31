variable "project_name" {
  description = "Prefix applied to all resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "private_subnets_cidr" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
}

variable "public_subnets_cidr" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to use."
  type        = list(string)
}