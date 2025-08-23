# ------------------------------------------------------------------------------
# Cocktail recommendation service.
# This is also a demo of remote Model Context Protocol (MCP) 
# It will likely involve:
# - Data layer: Existing reserved RDS Postgres instance
# - API layer: Express.js hosted inside a Lambda function
# - Front-end: Static React SPA on S3 behind Cloudfront CDN
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.14"

  backend "s3" {
    profile = "terraform-dev"
    region  = "us-east-1"
    bucket  = "924586450630-terraform-state"
    key     = "cocktail_app/terraform.tfstate.json"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "terraform-dev"
}

# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------

module "cocktail_app" {
  source = "../../modules/cocktail_app"

  namespace    = "ik"
  env          = "dev"
  is_prod      = false
  project_name = "cocktail"

  git_repo   = "ikenley/mcp-cocktail"
  git_branch = "main"

  parent_domain_name = "ikenley.com"
  domain_name        = "cocktail.ikenley.com"

  description = "MCP-friendly cocktail recommendations"

}
