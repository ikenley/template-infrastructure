# ------------------------------------------------------------------------------
# api_gateway.tf
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "api_gateway_api_endpoint" {
  name  = "${local.output_prefix}/api_gateway_api_endpoint"
  type  = "String"
  value = aws_apigatewayv2_api.this.api_endpoint
}

output "api_gateway_api_endpoint" {
  value = aws_apigatewayv2_api.this.api_endpoint
}

# ------------------------------------------------------------------------------
# lambda.tf
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "lambda_function_arn" {
  name  = "${local.output_prefix}/lambda_function_arn"
  type  = "String"
  value = aws_lambda_function.this.arn
}

output "lambda_function_arn" {
  value = aws_lambda_function.this.arn
}

resource "aws_ssm_parameter" "lambda_function_name" {
  name  = "${local.output_prefix}/lambda_function_name"
  type  = "String"
  value = aws_lambda_function.this.function_name
}

output "lambda_function_name" {
  value = aws_lambda_function.this.function_name
}

resource "aws_ssm_parameter" "lambda_role_arn" {
  name  = "${local.output_prefix}/lambda_role_arn"
  type  = "String"
  value = aws_iam_role.lambda.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda.arn
}

resource "aws_ssm_parameter" "lambda_role_name" {
  name  = "${local.output_prefix}/lambda_role_name"
  type  = "String"
  value = aws_iam_role.lambda.name
}

output "lambda_role_name" {
  value = aws_iam_role.lambda.name
}
