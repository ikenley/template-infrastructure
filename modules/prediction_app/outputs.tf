resource "aws_ssm_parameter" "revisit_prediction__pg_connection" {
  name  = local.pg_connection_parm_name
  type  = "SecureString"
  overwrite = true 
  value = jsonencode({
    "host":"${local.pghost}",
    "port":"${local.pgport}",
    "user":"revisit_prediction_user",
    "password":"${random_password.revisit_prediction_user.result}",
    "database":"${local.pgdatabase}"
  })
}

resource "aws_ssm_parameter" "revisit_prediction__pgpassword" {
  name  = "${local.output_prefix}/revisit_prediction/pgpassword"
  type  = "SecureString"
  overwrite = true 
  value = random_password.revisit_prediction_user.result
}

# Used only for local dev
resource "aws_ssm_parameter" "revisit_prediction_local__pg_connection" {
  name  = "${local.output_prefix}/revisit_prediction_local/pg_connection"
  type  = "SecureString"
  value = "SET_FOR_LOCAL_ENV"

  overwrite = false 

  # populate this via data sources
  lifecycle {  
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "flyway_admin__pguser" {
  name  = "${local.output_prefix}/flyway_admin/pguser"
  type  = "SecureString"
  value = "flyway_admin"
}

resource "aws_ssm_parameter" "flyway_admin__pgpassword" {
  name  = "${local.output_prefix}/flyway_admin/pgpassword"
  type  = "SecureString"
  value = random_password.flyway_admin.result
}

resource "aws_ssm_parameter" "prediction_app_user__pguser" {
  name  = "${local.output_prefix}/prediction_app_user/pguser"
  type  = "SecureString"
  value = "prediction_app_user"
}

resource "aws_ssm_parameter" "prediction_app_user__pgpassword" {
  name  = "${local.output_prefix}/prediction_app_user/pgpassword"
  type  = "SecureString"
  value = random_password.prediction_app_user.result
}

resource "aws_ssm_parameter" "prediction_app_user__connection_string" {
  name  = "${local.output_prefix}/prediction_app_user/connection_string"
  type  = "SecureString"
  value = "Host=${local.pghost};Port=${local.pgport};Database=${local.pgdatabase};Username=prediction_app_user;Password=${random_password.prediction_app_user.result}"
}

resource "aws_ssm_parameter" "auth_service__pg_connection" {
  name  = "${local.output_prefix}/auth_service/pg_connection"
  type  = "SecureString"
  overwrite = true 
  value = jsonencode({
    "host":"${local.pghost}",
    "port":"${local.pgport}",
    "user":"auth_service_user",
    "password":"${random_password.auth_service_user.result}",
    "database":"${local.pgdatabase}"
  })
}

resource "aws_ssm_parameter" "auth_service__pgpassword" {
  name  = "${local.output_prefix}/auth_service/pgpassword"
  type  = "SecureString"
  overwrite = true 
  value = random_password.auth_service_user.result
}

# Used only for local dev
resource "aws_ssm_parameter" "auth_service_local__pg_connection" {
  name  = "${local.output_prefix}/auth_service_local/pg_connection"
  type  = "SecureString"
  value = "SET_FOR_LOCAL_VALUES"

  overwrite = false 

  # populate this via data sources
  lifecycle {  
    ignore_changes = [value]
  }
}

# ------------------------------------------------------------------------------
# revisit_prediction.tf
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "revisit_prediction__function_arn" {
  name  = "${local.output_prefix}/revisit_prediction/function_arn"
  type  = "SecureString"
  value = module.revisit_prediction_lambda.lambda_function_arn
}

resource "aws_ssm_parameter" "revisit_prediction__function_name" {
  name  = "${local.output_prefix}/revisit_prediction/function_name"
  type  = "SecureString"
  value = module.revisit_prediction_lambda.lambda_function_name
}

#------------------------------------------------------------------------------
# Configuration parameters
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "auth_jwt_authority" {
  name      = "/${var.name}/app/auth/jwt-authority"
  type      = "SecureString"
  value     = var.auth_jwt_authority
  overwrite = true

  tags = local.tags
}

resource "aws_ssm_parameter" "auth_cognito_users_pool_id" {
  name      = "/${var.name}/app/auth/pool-id"
  type      = "SecureString"
  value     = var.auth_cognito_users_pool_id
  overwrite = true
}

resource "aws_ssm_parameter" "auth_client_id" {
  name      = "/${var.name}/app/auth/client-id"
  type      = "SecureString"
  value     = var.auth_client_id
  overwrite = true
}

resource "aws_ssm_parameter" "auth_aud" {
  name      = "/${var.name}/app/auth/aud"
  type      = "SecureString"
  value     = var.auth_aud
  overwrite = true
}