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

# ALB
output "alb_public_arn" {
  value = module.core.alb_public_arn
}

output "alb_public_sg_id" {
  description = "The ID of the ALB security group"
  value       = module.core.alb_public_sg_id
}

# output "alb_private_arn" {
#   value = module.core.alb_private_arn
# }

# output "alb_private_sg_id" {
#   description = "The ID of the ALB security group"
#   value       = module.core.alb_private_sg_id
# }

# S3
output "logs_s3_bucket_name" {
  description = "S3 bucket used for logs"
  value = module.core.logs_s3_bucket_name
}

output "code_pipeline_s3_bucket_name" {
  description = "S3 bucket used for CodePipeline artifacts"
  value = module.core.code_pipeline_s3_bucket_name
}

output "data_lake_s3_bucket_name" {
  description = "S3 bucket used for data lake"
  value = module.core.data_lake_s3_bucket_name
}

# AWS ECS Fargate cluster
output "ecs_cluster_arn" {
  description = "ARN of ECS Fargate cluster"
  value       = module.core.ecs_cluster_arn
}

output "ecs_cluster_name" {
  description = "Name of ECS Fargate cluster"
  value       = module.core.ecs_cluster_name
}