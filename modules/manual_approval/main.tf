#-------------------------------------------------------------------------------
# Main local configuration
#-------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  id            = "${var.namespace}-${var.env}-${var.project}-manual-approve"
  output_prefix = "/${var.namespace}/${var.env}/${var.project}/manual-approve"

  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    is_prod     = var.is_prod
  })
}
