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
    key     = "dev/ai_agent/terraform.tfstate.json"
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
  source = "../../modules/ai_agent"

  providers = {
    aws.primary  = aws.primary
    aws.failover = aws.failover
  }

  namespace = "ik"
  env       = "dev"
  project   = "ai"
  is_prod   = false

  base_domain = "ikenley.com"

  primary_rds_availability_zones = [
    "us-east-1a"
    , "us-east-1b"
    , "us-east-1d"
  ]

}
