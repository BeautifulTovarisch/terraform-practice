data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_id" "networking" {
  byte_length = 4
}

locals {
  vpc_cidr = "10.0.0.0/16"
  AZs      = slice(data.aws_availability_zones.available.names, 0, 1)

  tags = {
    Group       = "${random_id.networking.hex}"
    Project     = "demo"
    Environment = "dev"
  }
}

# VPC
# CIDR: 10.0.0.0/16
# Nat Gateway
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "vpc-${random_id.networking.hex}-tf-example"

  azs = local.AZs

  # Options

  enable_nat_gateway            = true
  single_nat_gateway            = true
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  enable_flow_log = false

  cidr = local.vpc_cidr

  # TODO: Calculate subnets using 'cidrsubnets' function
  private_subnets = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]

  # 10.0.0.0/24 not used?
  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  tags = local.tags
}

# Security Groups
# Application:
#   TCP:8080 from HostIP/32
# LoadBalancer:
#   TCP:8080 from HostIP/32

module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.0.0"

  name        = "security-group-${random_id.networking.hex}-application"
  description = "Ingress rules with 8080 open for Web Application"
  vpc_id      = module.vpc.vpc_id

  # Ingress from VPC
  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]

  ingress_with_cidr_blocks = [
    {
      description = "Web application port"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      # IP/32 of local machine
      cidr_blocks = "${var.user_host}/32"
    }
  ]

  tags = local.tags
}

module "lb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.0.0"

  name        = "security-group-${random_id.networking.hex}-load-balancer"
  description = "Ingress rules with 8080 open for Load Balancer"
  vpc_id      = module.vpc.vpc_id

  # Ingress from VPC
  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]

  ingress_with_cidr_blocks = [
    {
      description = "Web application port"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      # IP/32 of local machine
      cidr_blocks = "${var.user_host}/32"
    }
  ]

  tags = local.tags
}
