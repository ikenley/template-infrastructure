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
  value = "TODO"

  overwrite = false 

  # TODO populate this via data sources
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