# ------------------------------------------------------------------------------
# Create the core VPC network infrastructure
# ------------------------------------------------------------------------------

locals {
  namespace   = "ik"
  env         = "dev"
  name        = "main"
  is_prod     = false
  domain_name = "ikenley.com"

  # Quick way to turn off expensive services
  # see also var.spend_money
  enable_bastion_host = true
  enable_client_vpn   = false
}

terraform {
  required_version = ">= 0.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.4.0"
    }
  }

  backend "s3" {
    profile = "terraform-dev"
    region  = "us-east-1"
    bucket  = "924586450630-terraform-state"
    key     = "core/terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"
  #profile = "terraform-dev"
}

module "core" {
  source = "../../modules/core"

  namespace         = local.namespace
  env               = local.env
  name              = local.name
  is_prod           = local.is_prod
  domain_name       = local.domain_name
  organization_name = "ikenley"

  static_s3_domain = "static.ikenley.com"

  spend_money = var.spend_money

  cidr          = "10.0.0.0/18"
  dns_server_ip = "10.0.0.2"

  azs              = ["us-east-1a", "us-east-1b"]
  private_subnets  = ["10.0.0.0/24", "10.0.1.0/24"]
  public_subnets   = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24"]

  vpc_client_cidr = "10.1.0.0/22"

  enable_s3_endpoint = var.spend_money

  enable_bastion_host = var.spend_money && local.enable_bastion_host
  enable_client_vpn   = var.spend_money && local.enable_client_vpn

  docker_username = "ikenley6"
  # This must be stored securely 
  # https://learn.hashicorp.com/tutorials/terraform/sensitive-variables
  docker_password = var.docker_password

  ses_email_address = "predictions.ikenley@gmail.com"

  codestar_connection_arn = "arn:aws:codestar-connections:us-east-1:924586450630:connection/73e9e607-3dc4-4a4d-9f81-a82c0030de6d"
  source_branch_name      = "main"

  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret

  tags = {}
}
