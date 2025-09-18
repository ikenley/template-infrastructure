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
    key     = "dev/network_demo/terraform.tfstate.json"
  }
}

provider "aws" {
  alias   = "hub"
  region  = "us-east-1"
  profile = "terraform-dev"
}

provider "aws" {
  alias   = "failover"
  region  = "us-west-2"
  profile = "terraform-dev"
}

# network-hub

#------------------------------------------------------------------------------
# Resources
#------------------------------------------------------------------------------

locals {
  namespace = "ik"
  env       = "dev"
  project   = "network-demo"
  is_prod   = false

  availability_zones = ["us-east-1a", "us-east-1b"]

  spend_money = true
}

module "network_hub" {
  source = "../../modules/network_hub_and_spoke"

  providers = {
    aws     = aws.hub
    aws.hub = aws.hub
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
      cidr : "10.11.0.0/16"
      availability_zones = local.availability_zones
    }
  }
}

