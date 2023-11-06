# ------------------------------------------------------------------------------
# Centralized auth service 
# https://github.com/ikenley/auth-service
# Also a demo of an cheap full-stack application
# 1. The current setup has close to zero marginal cost:
# - Data layer: Existing reserved RDS Postgres instance
# - API layer: Express.js hosted inside a Lambda function behind an ALB
# - Front-end: Static React application on S3 behind Cloudfront CDN
# 2. Thanks to the Docker-based setup, these could be converted to an 
#       ... enterprise-ready hosting strategy with modest refactoring
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  id            = "${var.namespace}-${var.env}-auth"
  output_prefix = "/${var.namespace}/${var.env}/auth"

  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    Namespace   = var.namespace
    is_prod     = var.is_prod
  })
}

