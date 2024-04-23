# ------------------------------------------------------------------------------
# Outputs
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "lambda_config" {
  name      = "${local.output_prefix}/lambda_config"
  type      = "SecureString"
  overwrite = true
  value = jsonencode({
    "COGNITO_USER_POOL_ID" : data.aws_ssm_parameter.cognito_user_pool_id.value,
    "COGNITO_USER_POOL_CLIENT_ID" : data.aws_ssm_parameter.cognito_client_id.value,
    "COGNITO_USER_POOL_CLIENT_SECRET" : data.aws_ssm_parameter.cognito_client_secret.value,
    "OPENAI_API_KEY" : "TODO"
  })

  lifecycle {
    ignore_changes = [ value ]
  }
}

