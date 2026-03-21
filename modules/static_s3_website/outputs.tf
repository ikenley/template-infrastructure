# ------------------------------------------------------------------------------
# s3_bucket.tf
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "bucket_arn" {
  name  = "${local.output_prefix}/bucket_arn"
  type  = "String"
  value = aws_s3_bucket.this.arn
}
output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}

resource "aws_ssm_parameter" "bucket_id" {
  name  = "${local.output_prefix}/bucket_id"
  type  = "String"
  value = aws_s3_bucket.this.id
}
output "bucket_id" {
  value = aws_s3_bucket.this.id
}

resource "aws_ssm_parameter" "cdn_distribution_id" {
  name  = "${local.output_prefix}/cdn_distribution_id"
  type  = "String"
  value = aws_cloudfront_distribution.this.id
}
output "cdn_distribution_id" {
  value = aws_cloudfront_distribution.this.id
}

resource "aws_ssm_parameter" "active_version" {
  count = var.enable_blue_green ? 1 : 0
  name  = "${local.output_prefix}/active_version"
  type  = "String"
  value = "none"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "kvs_arn" {
  count = var.enable_blue_green ? 1 : 0
  name  = "${local.output_prefix}/kvs_arn"
  type  = "String"
  value = aws_cloudfront_key_value_store.active_version[0].arn
}

output "active_version_ssm_parameter_name" {
  value = var.enable_blue_green ? aws_ssm_parameter.active_version[0].name : null
}

output "active_version_ssm_parameter_arn" {
  value = var.enable_blue_green ? aws_ssm_parameter.active_version[0].arn : null
}

output "kvs_arn" {
  value = var.enable_blue_green ? aws_cloudfront_key_value_store.active_version[0].arn : null
}