# ------------------------------------------------------------------------------
# s3_bucket.tf
# ------------------------------------------------------------------------------

# resource "aws_ssm_parameter" "bucket_arn" {
#   name  = "${local.output_prefix}/bucket_arn"
#   type  = "String"
#   value = aws_s3_bucket.this.arn
# }

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

