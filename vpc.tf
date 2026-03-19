data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnets  = [for index in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, index)]
  private_subnets = [for index in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, index + var.az_count)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = var.project_name
  cidr = var.vpc_cidr

  azs                     = local.azs
  public_subnets          = local.public_subnets
  private_subnets         = local.private_subnets
  map_public_ip_on_launch = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = false

  tags = {
    Terraform = "true"
    Project   = var.project_name
  }
}