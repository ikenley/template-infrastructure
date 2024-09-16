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

data "aws_caller_identity" "current" {}
data "aws_region" "current" {
  provider = aws.primary
}
data "aws_region" "failover" {
  provider = aws.failover
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name

  aws_region_primary  = data.aws_region.current.name
  aws_region_failover = data.aws_region.failover.name

  id            = "${var.namespace}-${var.env}-efs-demo"
  output_prefix = "/${var.namespace}/${var.env}/efs-demo"

  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    is_prod     = var.is_prod
    module      = "main_root"
  })
}
