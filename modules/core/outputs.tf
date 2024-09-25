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
  value = join(",", module.vpc.nat_public_ips)
}

# ALB
# output "alb_public_arn" {
#   value = module.alb_public.aws_lb_lb_arn
# }

# resource "aws_ssm_parameter" "alb_public_arn" {
#   name  = "/${var.namespace}/${var.env}/core/alb_public_arn"
#   type  = "String"
#   value = module.alb_public.aws_lb_lb_arn
# }

# output "alb_public_sg_id" {
#   description = "The ID of the ALB security group"
#   value       = module.alb_public.aws_security_group_lb_access_sg_id
# }

# resource "aws_ssm_parameter" "alb_public_sg_id" {
#   name  = "/${var.namespace}/${var.env}/core/alb_public_sg_id"
#   type  = "String"
#   value = module.alb_public.aws_security_group_lb_access_sg_id
# }

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

resource "aws_ssm_parameter" "s3_artifacts_name" {
  name  = "/${var.namespace}/${var.env}/core/s3_artifacts_name"
  type  = "String"
  value = module.s3_bucket_artifacts.s3_bucket_name
}

resource "aws_ssm_parameter" "s3_artifacts_arn" {
  name  = "/${var.namespace}/${var.env}/core/s3_artifacts_arn"
  type  = "String"
  value = module.s3_bucket_artifacts.s3_bucket_arn
}

output "s3_install_name" {
  description = "S3 bucket used for install scripts bucket"
  value       = module.s3_bucket_install.s3_bucket_name
}

resource "aws_ssm_parameter" "s3_install_name" {
  name  = "/${var.namespace}/${var.env}/core/s3_install_name"
  type  = "String"
  value = module.s3_bucket_install.s3_bucket_name
}

resource "aws_ssm_parameter" "s3_install_arn" {
  name  = "/${var.namespace}/${var.env}/core/s3_install_arn"
  type  = "String"
  value = module.s3_bucket_install.s3_bucket_arn
}

output "s3_knowledge_base_name" {
  description = "S3 bucket used for knowledge_base scripts bucket"
  value       = module.s3_bucket_knowledge_base.s3_bucket_name
}

resource "aws_ssm_parameter" "s3_knowledge_base_name" {
  name  = "/${var.namespace}/${var.env}/core/s3_knowledge_base_name"
  type  = "String"
  value = module.s3_bucket_knowledge_base.s3_bucket_name
}

resource "aws_ssm_parameter" "s3_knowledge_base_arn" {
  name  = "/${var.namespace}/${var.env}/core/s3_knowledge_base_arn"
  type  = "String"
  value = module.s3_bucket_knowledge_base.s3_bucket_arn
}

output "logs_s3_bucket_name" {
  description = "S3 bucket used for logs"
  value       = module.s3_bucket_logs.s3_bucket_name
}

resource "aws_ssm_parameter" "logs_s3_bucket_name" {
  name  = "/${var.namespace}/${var.env}/core/logs_s3_bucket_name"
  type  = "String"
  value = module.s3_bucket_logs.s3_bucket_name
}

resource "aws_ssm_parameter" "logs_s3_bucket_arn" {
  name  = "/${var.namespace}/${var.env}/core/logs_s3_bucket_arn"
  type  = "String"
  value = module.s3_bucket_logs.s3_bucket_arn
}

output "code_pipeline_s3_bucket_name" {
  description = "S3 bucket used for CodePipeline artifacts"
  value       = module.s3_bucket_codepipeline.s3_bucket_name
}

resource "aws_ssm_parameter" "code_pipeline_s3_bucket_name" {
  name  = "/${var.namespace}/${var.env}/core/code_pipeline_s3_bucket_name"
  type  = "String"
  value = module.s3_bucket_codepipeline.s3_bucket_name
}

resource "aws_ssm_parameter" "code_pipeline_s3_bucket_arn" {
  name  = "/${var.namespace}/${var.env}/core/code_pipeline_s3_bucket_arn"
  type  = "String"
  value = module.s3_bucket_codepipeline.s3_bucket_arn
}

output "data_lake_s3_bucket_name" {
  description = "S3 bucket used for data lake"
  value       = module.s3_bucket_data_lake.s3_bucket_name
}

resource "aws_ssm_parameter" "data_lake_s3_bucket_name" {
  name  = "/${var.namespace}/${var.env}/core/data_lake_s3_bucket_name"
  type  = "String"
  value = module.s3_bucket_data_lake.s3_bucket_name
}

resource "aws_ssm_parameter" "data_lake_s3_bucket_arn" {
  name  = "/${var.namespace}/${var.env}/core/data_lake_s3_bucket_arn"
  type  = "String"
  value = module.s3_bucket_data_lake.s3_bucket_arn
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

# SES
output "ses_email_address" {
  value = aws_ses_email_identity.this.email
}

resource "aws_ssm_parameter" "ses_email_address" {
  name  = "/${var.namespace}/${var.env}/core/ses_email_address"
  type  = "String"
  value = aws_ses_email_identity.this.email
}

output "ses_email_arn" {
  value = aws_ses_email_identity.this.arn
}

resource "aws_ssm_parameter" "ses_email_arn" {
  name  = "/${var.namespace}/${var.env}/core/ses_email_arn"
  type  = "String"
  value = aws_ses_email_identity.this.arn
}

resource "aws_ssm_parameter" "codeartifact_domain_arn" {
  name  = "/${var.namespace}/${var.env}/core/codeartifact_domain_arn"
  type  = "String"
  value = aws_codeartifact_domain.this.arn
}

resource "aws_ssm_parameter" "codeartifact_domain_name" {
  name  = "/${var.namespace}/${var.env}/core/codeartifact_domain_name"
  type  = "String"
  value = aws_codeartifact_domain.this.domain
}

resource "aws_ssm_parameter" "codeartifact_domain_owner" {
  name  = "/${var.namespace}/${var.env}/core/codeartifact_domain_owner"
  type  = "String"
  value = aws_codeartifact_domain.this.owner
}

resource "aws_ssm_parameter" "codeartifact_repo_arn" {
  name  = "/${var.namespace}/${var.env}/core/codeartifact_repo_arn"
  type  = "String"
  value = aws_codeartifact_repository.this.arn
}

resource "aws_ssm_parameter" "codeartifact_repo_name" {
  name  = "/${var.namespace}/${var.env}/core/codeartifact_repo_name"
  type  = "String"
  value = aws_codeartifact_repository.this.repository
}

# SFTP
output "sftp_s3_bucket_name" {
  description = "S3 bucket used for AWS Transfer Family for SFTP"
  value       = module.s3_bucket_sftp.s3_bucket_name
}

resource "aws_ssm_parameter" "sftp_s3_bucket_name" {
  name  = "/${var.namespace}/${var.env}/core/sftp_s3_bucket_name"
  type  = "String"
  value = module.s3_bucket_sftp.s3_bucket_name
}

# CICD shared resources
resource "aws_ssm_parameter" "codestar_connection_arn" {
  name  = "/${var.namespace}/${var.env}/core/codestar_connection_arn"
  type  = "String"
  value = var.codestar_connection_arn
}

#------------------------------------------------------------------------------
# cognito.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "cognito_user_pool_arn" {
  name  = "/${var.namespace}/${var.env}/core/cognito/user_pool_arn"
  type  = "String"
  value = aws_cognito_user_pool.this.arn
}

resource "aws_ssm_parameter" "cognito_user_pool_domain" {
  name  = "/${var.namespace}/${var.env}/core/cognito/user_pool_domain"
  type  = "String"
  value = local.auth_domain
}

resource "aws_ssm_parameter" "cognito_user_pool_id" {
  name  = "/${var.namespace}/${var.env}/core/cognito/user_pool_id"
  type  = "SecureString"
  value = aws_cognito_user_pool.this.id
}

resource "aws_ssm_parameter" "cognito_client_id" {
  name  = "/${var.namespace}/${var.env}/core/cognito/client_id"
  type  = "SecureString"
  value = aws_cognito_user_pool_client.main.id
}

resource "aws_ssm_parameter" "cognito_client_secret" {
  name  = "/${var.namespace}/${var.env}/core/cognito/client_secret"
  type  = "SecureString"
  value = aws_cognito_user_pool_client.main.client_secret
}

resource "aws_ssm_parameter" "cognito_google_client_id" {
  name  = "/${var.namespace}/${var.env}/core/cognito/google_client_id"
  type  = "SecureString"
  value = var.google_client_id
}

resource "aws_ssm_parameter" "cognito_google_client_secret" {
  name  = "/${var.namespace}/${var.env}/core/cognito/google_client_secret"
  type  = "SecureString"
  value = var.google_client_secret
}

resource "aws_ssm_parameter" "authorized_emails" {
  name      = "/${var.namespace}/${var.env}/core/authorized_emails"
  type      = "SecureString"
  overwrite = true
  value     = jsonencode(["user@example.com"])

  lifecycle {
    ignore_changes = [value]
  }
}

#------------------------------------------------------------------------------
# event.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "event_bus_arn" {
  name  = "/${var.namespace}/${var.env}/core/event_bus_arn"
  type  = "String"
  value = aws_cloudwatch_event_bus.main.arn
}

resource "aws_ssm_parameter" "event_bus_name" {
  name  = "/${var.namespace}/${var.env}/core/event_bus_name"
  type  = "String"
  value = aws_cloudwatch_event_bus.main.name
}

#------------------------------------------------------------------------------
# oidc_github.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "oidc_github_provider_arn" {
  name  = "/${var.namespace}/${var.env}/core/oidc_github_provider_arn"
  type  = "String"
  value = aws_iam_openid_connect_provider.github.arn
}

resource "aws_ssm_parameter" "oidc_github_role_arn" {
  name  = "/${var.namespace}/${var.env}/core/oidc_github_role_arn"
  type  = "String"
  value = aws_iam_role.github.arn
}

resource "aws_ssm_parameter" "oidc_github_role_name" {
  name  = "/${var.namespace}/${var.env}/core/oidc_github_role_name"
  type  = "String"
  value = aws_iam_role.github.name
}
