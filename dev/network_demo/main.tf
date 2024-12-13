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

# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------

module "main" {
  source = "../../modules/network_hub"

  providers = {
    aws         = aws.primary
    aws.primary = aws.primary
  }

  namespace = "ik"
  env       = "dev"
  project   = "network-hub"
  is_prod   = false
}
