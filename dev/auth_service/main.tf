# ------------------------------------------------------------------------------
# Centralized authentication microservice for use with Amazon Cognito hosted UI.
# For more info, see: https://github.com/ikenley/auth-service
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.14"

  backend "s3" {
    profile = "terraform-dev"
    region  = "us-east-1"
    bucket  = "924586450630-terraform-state"
    key     = "auth_service/terraform.tfstate.json"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "terraform-dev"
}

# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------

module "auth_service" {
  source = "../../modules/auth_service"

  namespace    = "ik"
  env          = "dev"
  is_prod      = false
  project_name = "auth"

  git_repo   = "ikenley/auth-service"
  git_branch = "main"

  parent_domain_name = "ikenley.com"
  domain_name        = "auth-service.ikenley.com"
  url_path_prefix    = "auth"

  description = "Centralized authentication microservice"

}
