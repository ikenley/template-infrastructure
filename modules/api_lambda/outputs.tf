# ------------------------------------------------------------------------------
# s3_bucket.tf
# ------------------------------------------------------------------------------

# resource "aws_ssm_parameter" "bucket_arn" {
#   name  = "${local.output_prefix}/bucket_arn"
#   type  = "String"
#   value = aws_s3_bucket.this.arn
# }

# resource "aws_ssm_parameter" "bucket_id" {
#   name  = "${local.output_prefix}/bucket_id"
#   type  = "String"
#   value = aws_s3_bucket.this.id
# }
