
# ------------------------------------------------------------------------------
# Regional resources
# ------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id       = data.aws_caller_identity.current.account_id
  lb_internal_name = "${var.name}-alb-internal"
  # Need to pre-calculate the bucket name to avoid dependency loop
  lb_log_bucket_name = "${local.account_id}-logs"

  id = "${var.namespace}-${var.env}-${var.name}-core"

  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    is_prod     = var.is_prod
  })
}

# ------------------------------------------------------------------------------
# Docker credentials
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "docker_username" {
  name  = "/docker/username"
  type  = "String"
  value = var.docker_username

  tags = local.tags
}

resource "aws_ssm_parameter" "docker_password" {
  name  = "/docker/password"
  type  = "SecureString"
  value = var.docker_password

  tags = local.tags
}

# ------------------------------------------------------------------------------
# Bastion host
# ------------------------------------------------------------------------------

module "bastion_host" {
  count = var.enable_bastion_host ? 1 : 0

  source = "../../bastion_host"

  namespace = var.namespace
  env       = var.env
  name      = var.name

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}

# ------------------------------------------------------------------------------
# ECS Fargate Cluster
# ------------------------------------------------------------------------------

resource "aws_ecs_cluster" "this" {
  name = var.name

  tags = local.tags
}
