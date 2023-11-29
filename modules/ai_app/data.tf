locals {
  core_output_prefix = "/${var.namespace}/${var.env}/core"
  auth_output_prefix = "/${var.namespace}/${var.env}/auth"
}

# Core management
data "aws_ssm_parameter" "logs_s3_bucket_name" {
  name  = "${local.core_output_prefix}/logs_s3_bucket_name"
}
data "aws_ssm_parameter" "ses_email_address" {
  name  = "${local.core_output_prefix}/ses_email_address"
}
data "aws_ssm_parameter" "authorized_emails" {
  name  = "${local.core_output_prefix}/authorized_emails"
}

# Network
locals {
  private_subnets = split(",", data.aws_ssm_parameter.private_subnets.value)
}

data "aws_ssm_parameter" "vpc_id" {
  name  = "${local.core_output_prefix}/vpc_id"
}
data "aws_ssm_parameter" "vpc_cidr" {
  name  = "${local.core_output_prefix}/vpc_cidr"
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

# auth
data "aws_ssm_parameter" "auth_domain_name" {
  name  = "${local.auth_output_prefix}/domain_name"
}
