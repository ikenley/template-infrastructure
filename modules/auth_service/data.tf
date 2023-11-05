locals {
  core_output_prefix = "/${var.namespace}/${var.env}/core"
  rds_output_prefix = "/${var.namespace}/${var.env}/main-pg-01"
}

# Core management
data "aws_ssm_parameter" "logs_s3_bucket_name" {
  name  = "${local.core_output_prefix}/logs_s3_bucket_name"
}

# Network
locals {
  private_subnets = split(",", data.aws_ssm_parameter.private_subnets.value)
}

data "aws_ssm_parameter" "vpc_id" {
  name  = "${local.core_output_prefix}/vpc_id"
}

data "aws_ssm_parameter" "private_subnets" {
  name  = "${local.core_output_prefix}/private_subnets"
}

# CI/CD
data "aws_ssm_parameter" "code_pipeline_s3_bucket_name" {
  name  = "${local.core_output_prefix}/code_pipeline_s3_bucket_name"
}
data "aws_ssm_parameter" "codestar_connection_arn" {
  name  = "${local.core_output_prefix}/codestar_connection_arn"
}

# Cognito
data "aws_ssm_parameter" "cognito_user_pool_id" {
  name  = "${local.core_output_prefix}/cognito/user_pool_id"
}
data "aws_ssm_parameter" "cognito_client_id" {
  name  = "${local.core_output_prefix}/cognito/client_id"
}
data "aws_ssm_parameter" "cognito_client_secret" {
  name  = "${local.core_output_prefix}/cognito/client_secret"
}
data "aws_ssm_parameter" "cognito_user_pool_domain" {
  name  = "${local.core_output_prefix}/cognito/user_pool_domain"
}

# DB connection
data "aws_ssm_parameter" "db_instance_address" {
  name  = "${local.rds_output_prefix}/db_instance_address"
}
data "aws_ssm_parameter" "db_instance_port" {
  name  = "${local.rds_output_prefix}/db_instance_port"
}
data "aws_ssm_parameter" "db_database_name" {
  name  = "${local.rds_output_prefix}/db_database_name"
}
data "aws_ssm_parameter" "db_database_password" {
  name  = "/${var.namespace}/${var.env}/prediction/auth_service/pgpassword"
}
