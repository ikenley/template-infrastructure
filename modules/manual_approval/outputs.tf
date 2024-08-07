# ------------------------------------------------------------------------------
# sfn_state_machine.tf
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "api_gateway_invoke_url" {
  name  = "${local.output_prefix}/api_gateway_invoke_url"
  type  = "String"
  value = "https://${aws_api_gateway_rest_api.api_gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.api_gateway.stage_name}"
}

output "api_gateway_invoke_url" {
  value = "https://${aws_api_gateway_rest_api.api_gateway.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.api_gateway.stage_name}"
}

resource "aws_ssm_parameter" "send_lambda_function_arn" {
  name  = "${local.output_prefix}/send_lambda_function_arn"
  type  = "String"
  value = module.send_lambda.lambda_function_arn
}

output "send_lambda_function_arn" {
  value = module.send_lambda.lambda_function_arn
}

resource "aws_ssm_parameter" "receive_lambda_function_arn" {
  name  = "${local.output_prefix}/receive_lambda_function_arn"
  type  = "String"
  value = module.receive_lambda.lambda_function_arn
}

output "receive_lambda_function_arn" {
  value = module.receive_lambda.lambda_function_arn
}

resource "aws_ssm_parameter" "sns_email_topic_arn" {
  name  = "${local.output_prefix}/sns_email_topic_arn"
  type  = "String"
  value = aws_sns_topic.sns_human_approval_email_topic.arn
}

output "sns_email_topic_arn" {
  value = aws_sns_topic.sns_human_approval_email_topic.arn
}

resource "aws_ssm_parameter" "sns_email_topic_id" {
  name  = "${local.output_prefix}/sns_email_topic_id"
  type  = "String"
  value = aws_sns_topic.sns_human_approval_email_topic.id
}

output "sns_email_topic_id" {
  value = aws_sns_topic.sns_human_approval_email_topic.id
}

