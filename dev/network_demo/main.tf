# ------------------------------------------------------------------------------
# network-demo
# Example of multi-account AWS network with a central "hub" network
# All outbound (egress) traffic will be monitored by AWS Network Firewall
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.14"

  backend "s3" {
    profile = "terraform-dev"
    region  = "us-east-1"
    bucket  = "924586450630-terraform-state"
    key     = "dev/network_hub_example/terraform.tfstate.json"
  }
}

provider "aws" {
  alias   = "hub"
  region  = "us-east-1"
  profile = "network-hub"
}

provider "aws" {
  alias   = "spoke_abc"
  region  = "us-east-1"
  profile = "terraform-dev"
}

#------------------------------------------------------------------------------
# Resources
#------------------------------------------------------------------------------

locals {
  namespace = "ik"
  env       = "dev"
  project   = "network-demo"
  is_prod   = false

  availability_zones = ["us-east-1a", "us-east-1b"]

  example_spoke_abc_cidr = "10.11.0.0/16"

  spend_money = true
}

module "example_vpc_spoke_abc" {
  source = "../../modules/network_spoke_example"

  providers = {
    aws = aws.spoke_abc
  }

  namespace = local.namespace
  env       = local.env
  project   = local.project
  is_prod   = local.is_prod

  cidr = local.example_spoke_abc_cidr

  availability_zones = local.availability_zones

  enable_nat_gateway = local.spend_money
  single_nat_gateway = false

  # Add after initial creation 
  transit_gateway_id = ""
}

module "network_hub" {
  source = "../../modules/network_hub"

  providers = {
    aws     = aws.hub
    aws.hub = aws.hub

    aws.spoke_abc = aws.spoke_abc
  }

  namespace = local.namespace
  env       = local.env
  project   = local.project
  is_prod   = local.is_prod

  hub_vpc_cidr = "10.255.0.0/16"

  availability_zones = local.availability_zones

  enable_nat_gateway = local.spend_money
  single_nat_gateway = false

  spoke_vpcs = {
    spoke_abc = {
      id = module.example_vpc_spoke_abc.vpc_id
      cidr : local.example_spoke_abc_cidr
      transit_gateway_subnet_ids = module.example_vpc_spoke_abc.transit_gw_subnet_ids
    }
  }
}

