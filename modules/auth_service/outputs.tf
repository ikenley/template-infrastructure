# ------------------------------------------------------------------------------
# TODO
# ------------------------------------------------------------------------------

# resource "aws_ssm_parameter" "revisit_prediction__pgpassword" {
#   name  = "${local.output_prefix}/revisit_prediction/pgpassword"
#   type  = "SecureString"
#   overwrite = true 
#   value = random_password.revisit_prediction_user.result
# }

resource "aws_ssm_parameter" "lambda_config" {
  name      = "${local.output_prefix}/lambda_config"
  type      = "SecureString"
  overwrite = true
  value = jsonencode({
    "COGNITO_OAUTH_URL_PREFIX" : "https://${data.aws_ssm_parameter.cognito_user_pool_domain.value}",
    "COGNITO_OAUTH_REDIRECT_URL_PREFIX" : "https://${local.api_domain_name}",
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
