# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

# resource "aws_ssm_parameter" "revisit_prediction__pgpassword" {
#   name  = "${local.output_prefix}/revisit_prediction/pgpassword"
#   type  = "SecureString"
#   overwrite = true 
#   value = random_password.revisit_prediction_user.result
# }

resource "aws_ssm_parameter" "auth_service_domain_name" {
  name      = "${local.output_prefix}/domain_name"
  type      = "String"
  overwrite = true
  value     = var.domain_name
}

resource "aws_ssm_parameter" "lambda_config" {
  name      = "${local.output_prefix}/lambda_config"
  type      = "SecureString"
  overwrite = true
  value = jsonencode({
    "COGNITO_OAUTH_URL_PREFIX" : "https://${data.aws_ssm_parameter.cognito_user_pool_domain.value}",
    "COGNITO_OAUTH_REDIRECT_URL_PREFIX" : "https://${var.domain_name}",
    "COGNITO_USER_POOL_ID" : data.aws_ssm_parameter.cognito_user_pool_id.value,
    "COGNITO_USER_POOL_CLIENT_ID" : data.aws_ssm_parameter.cognito_client_id.value,
    "COGNITO_USER_POOL_CLIENT_SECRET" : data.aws_ssm_parameter.cognito_client_secret.value,
    "PGHOST" : data.aws_ssm_parameter.db_instance_address.value,
    "PGPORT" : data.aws_ssm_parameter.db_instance_port.value,
    "PGUSER" : "auth_service_user",
    "PGPASSWORD" : data.aws_ssm_parameter.db_database_password.value,
    "PGDATABASE" : data.aws_ssm_parameter.db_database_name.value,
  })
}


# ------------------------------------------------------------------------------
# api_lambda
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "user_table_arn" {
  name  = "${local.output_prefix}/user_table_arn"
  type  = "String"
  value = aws_dynamodb_table.user.arn
}

resource "aws_ssm_parameter" "user_table_name" {
  name  = "${local.output_prefix}/user_table_name"
  type  = "String"
  value = aws_dynamodb_table.user.name
}

resource "aws_ssm_parameter" "oauth_state_table_arn" {
  name  = "${local.output_prefix}/oauth_state_table_arn"
  type  = "String"
  value = aws_dynamodb_table.oauth_state.arn
}

resource "aws_ssm_parameter" "oauth_state_table_name" {
  name  = "${local.output_prefix}/oauth_state_table_name"
  type  = "String"
  value = aws_dynamodb_table.oauth_state.name
}
