#-------------------------------------------------------------------------------
# Main local varialble setup
#-------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.70.0"
      configuration_aliases = [aws.hub, aws.spoke_abc]
    }
  }
}

data "aws_caller_identity" "hub" {}

data "aws_partition" "hub" {
  provider = aws.hub
}

data "aws_region" "hub" {
  provider = aws.hub
}

locals {
  account_id = data.aws_caller_identity.hub.account_id

  aws_region_hub = data.aws_region.hub.name

  id            = "${var.namespace}-${var.env}-${var.project}"
  output_prefix = "/${var.namespace}/${var.env}/${var.project}"

  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    is_prod     = var.is_prod
    repo        = "https://github.com/ikenley/template-infrastructure"
    module      = "network_hub_and_spoke"
  })
}
