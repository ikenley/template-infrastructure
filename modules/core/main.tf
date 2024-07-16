
# ------------------------------------------------------------------------------
# VPC
# ------------------------------------------------------------------------------

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
# S3 buckets
# ------------------------------------------------------------------------------

module "s3_bucket_codepipeline" {
  source = "../s3_bucket"

  bucket_name_suffix = "code-pipeline"

  enable_archive = true

  tags = local.tags
}

# Data lake for storing base/staging data
# Each project will have its own s3 keyPrefix e.g. "template-app/base/file.csv"
# https://discourse.getdbt.com/t/how-we-structure-our-dbt-projects/355
module "s3_bucket_data_lake" {
  source = "../s3_bucket"

  bucket_name_suffix = "data-lake"

  tags = local.tags
}

# Build artifacts
module "s3_bucket_artifacts" {
  source = "../s3_bucket"

  bucket_name_suffix = "artifacts"

  enable_archive = true

  tags = local.tags
}

# Install scripts and configuration files for user_data etc.
module "s3_bucket_install" {
  source = "../s3_bucket"

  bucket_name_suffix = "install"

  tags = local.tags
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
# DNS
# ------------------------------------------------------------------------------
resource "aws_route53_zone" "public" {
  name = var.domain_name
}

# ------------------------------------------------------------------------------
# Load Balancers
# ------------------------------------------------------------------------------

# S3 BUCKET - For access logs
data "aws_elb_service_account" "default" {}

module "s3_bucket_logs" {
  source = "../s3_bucket"

  bucket_name_suffix = "logs"

  enable_archive = true

  bucket_policy = templatefile("${path.module}/bucket_policy.tpl", {
    bucket_name                 = local.lb_log_bucket_name
    account_id                  = local.account_id
    aws_elb_service_account_arn = data.aws_elb_service_account.default.arn
  })
}

# module "alb_public" {
#   source = "../ecs_alb"

#   name_prefix = "${var.name}-public"
#   vpc_id      = module.vpc.vpc_id

#   log_s3_bucket_name = module.s3_bucket_logs.s3_bucket_name

#   internal        = false
#   private_subnets = module.vpc.private_subnets
#   public_subnets  = module.vpc.public_subnets

#   dns_zone_id     = aws_route53_zone.public.zone_id
#   dns_domain_name = "xyz.${var.domain_name}"
# }

# module "alb_private" {
#   source = "../ecs_alb"

#   name_prefix = "${var.name}-private"
#   vpc_id      = var.vpc_id

#   log_s3_bucket_name = module.s3_bucket_logs.s3_bucket_name

#   internal        = true
#   private_subnets = module.vpc.private_subnets
#   public_subnets  = module.vpc.public_subnets

#   dns_zone_id     = aws_route53_zone.private.zone_id
#   dns_domain_name = "internal.${var.domain_name}"
# }

# ------------------------------------------------------------------------------
# Bastion host
# ------------------------------------------------------------------------------

module "bastion_host" {
  count = var.enable_bastion_host ? 1 : 0

  source = "../bastion_host"

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

# ------------------------------------------------------------------------------
# SES (Simple Email Service)
# ------------------------------------------------------------------------------
resource "aws_ses_email_identity" "this" {
  email = var.ses_email_address
}

# ------------------------------------------------------------------------------
# CodeArtifact
# See https://github.com/ikenley/code-artifact-npm-boilerplate
# ------------------------------------------------------------------------------

resource "aws_codeartifact_domain" "this" {
  domain = local.id
}

resource "aws_codeartifact_repository" "this" {
  repository = "main"
  domain     = aws_codeartifact_domain.this.domain

  upstream {
    repository_name = aws_codeartifact_repository.upstream_npm.repository
  }
}

resource "aws_codeartifact_repository" "upstream_npm" {
  repository = "${local.id}-npm"
  domain     = aws_codeartifact_domain.this.domain

  external_connections {
    external_connection_name = "public:npmjs"
  }
}

# ------------------------------------------------------------------------------
# AWS Transfer Family for SFTP
# ------------------------------------------------------------------------------

module "s3_bucket_sftp" {
  source = "../s3_bucket"

  bucket_name_suffix = "sftp"

  tags = local.tags
}

module "transfer_sftp" {
  source = "../transfer_sftp"

  namespace   = var.namespace
  env         = var.env
  name        = "main"
  is_prod     = var.is_prod
  spend_money = false # TODO revert this to var.spend_money

  domain_name      = "sftp.${var.domain_name}"
  route_53_zone_id = aws_route53_zone.public.zone_id

  tags = local.tags
}
