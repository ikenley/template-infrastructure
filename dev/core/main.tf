# ------------------------------------------------------------------------------
# Create the core VPC network infrastructure
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.14"

  backend "s3" {
    profile = "terraform-dev"
    region = "us-east-1"
    bucket = "924586450630-terraform-state"
    key    = "core/terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "terraform-dev"
}

module "core" {
  source  = "../../modules/core"

  cidr = "10.0.0.0/18" 

  azs                 = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  public_subnets      = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  database_subnets    = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]

  tags = {
    Environment = "dev"
  }
}
