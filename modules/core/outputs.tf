# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  value       = var.cidr
}

output "azs" {
  description = "A list of availability zones names or ids in the region"
  value       = var.azs
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

# ALB
output "alb_public_arn" {
  value = module.alb_public.aws_lb_lb_arn
}

output "alb_public_sg_id" {
  description = "The ID of the ALB security group"
  value       = module.alb_public.aws_security_group_lb_access_sg_id
}

# output "alb_private_arn" {
#   value = module.alb_private.aws_lb_lb_arn
# }

# output "alb_private_sg_id" {
#   description = "The ID of the ALB security group"
#   value       = module.alb_private.aws_security_group_lb_access_sg_id
# }

# S3

output "s3_artifacts_name" {
  description = "S3 bucket used for build artifacts"
  value       = module.s3_bucket_artifacts.s3_bucket_name
}

output "s3_install_name" {
  description = "S3 bucket used for install scripts bucket"
  value       = module.s3_bucket_install.s3_bucket_name
}

output "logs_s3_bucket_name" {
  description = "S3 bucket used for logs"
  value       = module.s3_bucket_logs.s3_bucket_name
}

output "code_pipeline_s3_bucket_name" {
  description = "S3 bucket used for CodePipeline artifacts"
  value       = module.s3_bucket_codepipeline.s3_bucket_name
}

output "data_lake_s3_bucket_name" {
  description = "S3 bucket used for data lake"
  value       = module.s3_bucket_data_lake.s3_bucket_name
}

# AWS ECS Fargate cluster
output "ecs_cluster_arn" {
  description = "ARN of ECS Fargate cluster"
  value       = aws_ecs_cluster.this.arn
}

output "ecs_cluster_name" {
  description = "Name of ECS Fargate cluster"
  value       = aws_ecs_cluster.this.name
}

# SES
output "ses_email_address" {
  value = aws_ses_email_identity.this.email
}
output "ses_email_arn" {
  value = aws_ses_email_identity.this.arn
}
