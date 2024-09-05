# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

resource "aws_ssm_parameter" "vpc_id" {
  name  = "/${var.namespace}/${var.env}/core/vpc_id"
  type  = "String"
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  value       = var.cidr
}

resource "aws_ssm_parameter" "vpc_cidr" {
  name  = "/${var.namespace}/${var.env}/core/vpc_cidr"
  type  = "String"
  value = var.cidr
}

output "azs" {
  description = "A list of availability zones names or ids in the region"
  value       = var.azs
}

resource "aws_ssm_parameter" "azs" {
  name  = "/${var.namespace}/${var.env}/core/azs"
  type  = "StringList"
  value = join(",", var.azs)
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

resource "aws_ssm_parameter" "private_subnets" {
  name  = "/${var.namespace}/${var.env}/core/private_subnets"
  type  = "StringList"
  value = join(",", module.vpc.private_subnets)
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

resource "aws_ssm_parameter" "public_subnets" {
  name  = "/${var.namespace}/${var.env}/core/public_subnets"
  type  = "StringList"
  value = join(",", module.vpc.public_subnets)
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

resource "aws_ssm_parameter" "database_subnets" {
  name  = "/${var.namespace}/${var.env}/core/database_subnets"
  type  = "StringList"
  value = join(",", module.vpc.database_subnets)
}

# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

resource "aws_ssm_parameter" "nat_public_ips" {
  name  = "/${var.namespace}/${var.env}/core/nat_public_ips"
  type  = "StringList"
  value = length(module.vpc.nat_public_ips) > 0 ? join(",", module.vpc.nat_public_ips) : "[]"
}

# AWS ECS Fargate cluster
output "ecs_cluster_arn" {
  description = "ARN of ECS Fargate cluster"
  value       = aws_ecs_cluster.this.arn
}

resource "aws_ssm_parameter" "ecs_cluster_arn" {
  name  = "/${var.namespace}/${var.env}/core/ecs_cluster_arn"
  type  = "String"
  value = aws_ecs_cluster.this.arn
}

output "ecs_cluster_name" {
  description = "Name of ECS Fargate cluster"
  value       = aws_ecs_cluster.this.name
}

resource "aws_ssm_parameter" "ecs_cluster_name" {
  name  = "/${var.namespace}/${var.env}/core/ecs_cluster_name"
  type  = "String"
  value = aws_ecs_cluster.this.name
}
