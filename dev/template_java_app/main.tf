# ------------------------------------------------------------------------------
# Create the core VPC network infrastructure
# ------------------------------------------------------------------------------

locals {
  name      = "template-java-app"
  namespace = "template-java-app"
  env       = "Development"
  is_prod   = false

  domain_name   = "ikenley.com"
  dns_subdomain = "templatejavaapp"
}

terraform {
  required_version = ">= 0.14"

  backend "s3" {
    profile = "terraform-dev"
    region  = "us-east-1"
    bucket  = "924586450630-terraform-state"
    key     = "template_java_app/terraform.tfstate"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "terraform-dev"
}

data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    profile = "terraform-dev"
    bucket  = "924586450630-terraform-state"
    key     = "core/terraform.tfstate"
    region  = "us-east-1"
  }
}

# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------

module "template_java_app" {
  source = "../../modules/template_java_app"

  name          = local.name
  namespace     = local.namespace
  env           = local.env
  is_prod       = local.is_prod
  domain_name   = local.domain_name
  dns_subdomain = local.dns_subdomain

  vpc_id           = data.terraform_remote_state.core.outputs.vpc_id
  vpc_cidr         = data.terraform_remote_state.core.outputs.vpc_cidr
  azs              = data.terraform_remote_state.core.outputs.azs
  public_subnets   = data.terraform_remote_state.core.outputs.public_subnets
  private_subnets  = data.terraform_remote_state.core.outputs.private_subnets
  database_subnets = data.terraform_remote_state.core.outputs.database_subnets

  host_in_public_subnets = false

  alb_arn   = data.terraform_remote_state.core.outputs.alb_public_arn
  alb_sg_id = data.terraform_remote_state.core.outputs.alb_public_sg_id

  ecs_cluster_arn  = data.terraform_remote_state.core.outputs.ecs_cluster_arn
  ecs_cluster_name = data.terraform_remote_state.core.outputs.ecs_cluster_name

  container_names  = ["client", "api"]
  container_ports  = [80, 5000]
  container_cpu    = 256
  container_memory = 512

  code_pipeline_s3_bucket_name = data.terraform_remote_state.core.outputs.code_pipeline_s3_bucket_name
  source_full_repository_id    = "ikenley/template-java-app"
  source_branch_name           = "main"
  codestar_connection_arn      = "arn:aws:codestar-connections:us-east-1:924586450630:connection/73e9e607-3dc4-4a4d-9f81-a82c0030de6d"

  auth_jwt_authority         = var.auth_jwt_authority
  auth_cognito_users_pool_id = var.auth_cognito_users_pool_id
  auth_client_id             = var.auth_client_id
  auth_aud                   = var.auth_aud

  ses_email_address = data.terraform_remote_state.core.outputs.ses_email_address
  ses_email_arn     = data.terraform_remote_state.core.outputs.ses_email_arn

  tags = {
    Environment = "dev"
  }
}
