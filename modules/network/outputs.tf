output "vpc_id" {
  description = "Identifier of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnets"
  value      = module.vpc.private_subnets[*]
}

output "security_group_ids" {
  description = "List of security group ids"
  value       = [module.app_security_group.security_group_id]
}
