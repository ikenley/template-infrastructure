#-------------------------------------------------------------------------------
# Main local varialble setup
#-------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.70.0"
      configuration_aliases = [aws.primary]
    }
  }
}

data "aws_caller_identity" "primary" {}

data "aws_partition" "primary" {
  provider = aws.primary
}

data "aws_region" "primary" {
  provider = aws.primary
}

locals {
  account_id = data.aws_caller_identity.primary.account_id

  aws_region_primary = data.aws_region.primary.name

  id            = "${var.namespace}-${var.env}-${var.project}"
  output_prefix = "/${var.namespace}/${var.env}/${var.project}"

  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    is_prod     = var.is_prod
    repo        = "https://github.com/ikenley/template-infrastructure"
    module      = "network_hub"
  })
}
