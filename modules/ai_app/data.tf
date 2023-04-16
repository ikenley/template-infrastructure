locals {
  core_output_prefix = "/${var.namespace}/${var.env}/core"
}


data "aws_ssm_parameter" "logs_s3_bucket_name" {
  name  = "${local.core_output_prefix}/logs_s3_bucket_name"
}