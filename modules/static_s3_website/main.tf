# ------------------------------------------------------------------------------
# A static S3 website behind a CloudFront CDN
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  id            = "${var.namespace}-${var.env}-${var.project_name}"
  output_prefix = "/${var.namespace}/${var.env}/${var.project_name}"

  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    Namespace   = var.namespace
    is_prod     = var.is_prod
  })
}
