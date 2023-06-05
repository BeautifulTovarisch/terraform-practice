# Multi-account Terraform example which creates the following infrastructure:
#
# - VPC
# - LoadBalancer
# - EC2
#
# Usage of infrastructure modules is demonstrated and resources are provisioned
# across two AWS accounts for Prod and Stage.

provider "aws" {
  region  = "us-east-1"
  profile = "admin"
}

terraform {
  required_version = "~> 1.4.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.1.0"
    }
  }
}

# VPC configuration is abstracted using the 'network' module
module "network" {
  source = "../modules/network"

  user_host = var.user_host
}

# EC2 Instances running a basic Apache website
module "compute" {
  source = "../modules/compute"

  subnet_ids         = module.network.private_subnet_ids[*]
  security_group_ids = [module.network.security_group_ids]

  depends_on = [module.network]
}

module "elb_http" {
  source  = "terraform-aws-modules/elb/aws"
  version = "4.0.1"

  name = "lb-tf-example"

  internal = false

  security_groups = [module.network.lb_security_group_id]
  subnets         = module.network.public_subnets

  instances           = module.compute.instance_ids
  number_of_instances = length(module.compute.instance_ids)

  listener = [{
    instance_port     = "8080"
    instance_protocol = "HTTP"
    lb_port           = "8080"
    lb_protocol       = "HTTP"
  }]

  health_check = {
    target              = "HTTP:8080/index.html"
    interval            = 10
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
  }
}
