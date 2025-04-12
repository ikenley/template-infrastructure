# ------------------------------------------------------------------------------
# efs-demo
# Example of AWS Step Function with various integrations
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.14"

  backend "s3" {
    profile = "terraform-dev"
    region  = "us-east-1"
    bucket  = "924586450630-terraform-state"
    key     = "dev/network_demo/terraform.tfstate.json"
  }
}

provider "aws" {
  alias   = "primary"
  region  = "us-east-1"
  profile = "terraform-dev"
}

provider "aws" {
  alias   = "failover"
  region  = "us-west-2"
  profile = "terraform-dev"
}

#------------------------------------------------------------------------------
# Resources
#------------------------------------------------------------------------------

locals {
  namespace = "ik"
  env       = "dev"
  project   = "network-hub"
  is_prod   = false

  spend_money = false
}

module "network_hub" {
  source = "../../modules/network_hub"

  providers = {
    aws         = aws.primary
    aws.primary = aws.primary
  }

  namespace = local.namespace
  env       = local.env
  project   = local.project
  is_prod   = local.is_prod

  cidr = "10.1.0.0/16"

  azs                     = ["us-east-1a", "us-east-1b"]
  public_subnets          = ["10.1.0.0/24", "10.1.1.0/24"]
  firewall_subnets        = ["10.1.2.0/24", "10.1.3.0/24"]
  transit_gateway_subnets = ["10.1.4.0/24", "10.1.5.0/24"]

  enable_nat_gateway = local.spend_money
  single_nat_gateway = false
}

