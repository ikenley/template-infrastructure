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