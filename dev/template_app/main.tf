# ------------------------------------------------------------------------------
# Create the core VPC network infrastructure
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.14"

  backend "s3" {
    profile = "terraform-dev"
    region  = "us-east-1"
    bucket  = "924586450630-terraform-state"
    key     = "template_app/terraform.tfstate"
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

module "application" {
  source = "../../modules/application"

  name = "template-app"

  vpc_id           = data.terraform_remote_state.core.outputs.vpc_id
  vpc_cidr         = data.terraform_remote_state.core.outputs.vpc_cidr
  azs              = data.terraform_remote_state.core.outputs.azs
  public_subnets   = data.terraform_remote_state.core.outputs.public_subnets
  private_subnets  = data.terraform_remote_state.core.outputs.private_subnets
  database_subnets = data.terraform_remote_state.core.outputs.database_subnets

  domain_name   = "antig-one-rav.com"
  dns_subdomain = "template-app-dev"

  container_name = "template-app"
  ecs_container_definitions = file("./container_definitions.json")
  container_memory          = 512
  container_cpu             = 256

  tags = {
    Environment = "dev"
  }
}
