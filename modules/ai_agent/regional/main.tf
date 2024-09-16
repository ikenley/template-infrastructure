#-------------------------------------------------------------------------------
# Main regional resources
#-------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.65.0"
      configuration_aliases = [aws]
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name

  id            = "${var.namespace}-${var.env}-efs-demo"
  output_prefix = "/${var.namespace}/${var.env}/efs-demo"

  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    is_prod     = var.is_prod
    module      = "main_regional"
  })
}
