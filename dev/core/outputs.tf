# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.core.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  value       = module.core.vpc_cidr
}

output "azs" {
  description = "A list of availability zones names or ids in the region"
  value       = module.core.azs
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.core.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.core.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.core.database_subnets
}

# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.core.nat_public_ips
}

