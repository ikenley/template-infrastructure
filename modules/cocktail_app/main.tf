# ------------------------------------------------------------------------------
# Cocktail recommendation service.
# This is also a demo of remote Model Context Protocol (MCP) 
# Also a demo of an cheap full-stack application
# It will likely involve:
# - Data layer: Existing reserved RDS Postgres instance
# - API layer: Express.js hosted inside a Lambda function behind an ALB
# - Front-end: Static React application on S3 behind Cloudfront CDN
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  id            = "${var.namespace}-${var.env}-cocktail"
  output_prefix = "/${var.namespace}/${var.env}/cocktail"

  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    Namespace   = var.namespace
    is_prod     = var.is_prod
  })
}

