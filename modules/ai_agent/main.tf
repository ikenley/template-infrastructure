#-------------------------------------------------------------------------------
# Main local varialble setup
#-------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.65.0"
      configuration_aliases = [aws.primary, aws.failover]
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
data "aws_region" "failover" {
  provider = aws.failover
}

locals {
  account_id = data.aws_caller_identity.primary.account_id

  aws_region_primary  = data.aws_region.primary.name
  aws_region_failover = data.aws_region.failover.name

  id            = "${var.namespace}-${var.env}-${var.project}-ai-agent"
  output_prefix = "/${var.namespace}/${var.env}/${var.project}/ai-agent"

  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    is_prod     = var.is_prod
    module      = "ai_agent"
  })
}
