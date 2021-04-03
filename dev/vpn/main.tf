# ------------------------------------------------------------------------------
# Create the VPN Client Endpoint
# ------------------------------------------------------------------------------

locals {
  name    = "template-app"
  env     = "dev"
  is_prod = false
}

terraform {
  required_version = ">= 0.14"

  backend "s3" {
    profile = "terraform-dev"
    region  = "us-east-1"
    bucket  = "924586450630-terraform-state"
    key     = "vpn/terraform.tfstate"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "terraform-dev"
}

data "terraform_remote_state" "core" {
  backend = "s3"
  config = {
    bucket = "924586450630-terraform-state"
    key    = "core/terraform.tfstate"
    region = "us-east-1"
  }
}

# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------

module "vpn" {
  source = "../../modules/vpn"

  name    = local.name
  env     = local.env
  is_prod = local.is_prod

  vpc_id   = data.terraform_remote_state.core.outputs.vpc_id
  vpc_cidr = data.terraform_remote_state.core.outputs.vpc_cidr

  server_certificate_arn     = "arn:aws:acm:us-east-1:924586450630:certificate/a4f0361e-a8b3-4f7f-9702-485be86b86cd"
  root_certificate_chain_arn = "arn:aws:acm:us-east-1:924586450630:certificate/b7810db4-ce20-4e74-93ce-1579c9c602b3"
  client_cidr_block          = "10.0.56.0/22"
  subnet_id                  = data.terraform_remote_state.core.outputs.private_subnets[0]

  tags = {
    Environment = "dev"
  }
}
