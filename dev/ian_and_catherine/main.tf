# ------------------------------------------------------------------------------
# Create the core VPC network infrastructure
# ------------------------------------------------------------------------------

locals {
  namespace   = "igk-chs"
  env         = "dev"
  is_prod     = false
  domain_name = "ian-and-catherine.com"
}

terraform {
  required_version = ">= 0.14"

  backend "s3" {
    profile = "terraform-dev"
    region  = "us-east-1"
    bucket  = "924586450630-terraform-state"
    key     = "ian_and_catherine/terraform.tfstate"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "terraform-dev"
}

module "dns_redirect" {
  source = "../../modules/dns_redirect"

  namespace   = local.namespace
  env         = local.env
  is_prod     = local.is_prod
  domain_name = local.domain_name

  redirect_url = "https://www.zola.com/wedding/ianandcatherine2022"

  tags = {}
}
