# ------------------------------------------------------------------------------
# Sanbox AI application. 
# Also a demo of an cheap full-stack application
# It will likely involve:
# - Data layer: Existing reserved RDS Postgres instance
# - API layer: Express.js hosted inside a Lambda function behind an ALB
# - Front-end: Static React application on S3 behind Cloudfront CDN
# ------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.14"

  backend "s3" {
    profile = "terraform-dev"
    region  = "us-east-1"
    bucket  = "924586450630-terraform-state"
    key     = "ai_app/terraform.tfstate.json"
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "terraform-dev"
}

# ------------------------------------------------------------------------------
# Resources
# ------------------------------------------------------------------------------

module "ai_app" {
  source = "../../modules/ai_app"

  namespace    = "ik"
  env          = "dev"
  is_prod      = false
  project_name = "ai"

  git_repo   = "ikenley/ai-app"
  git_branch = "vitest" #"main"

  parent_domain_name = "ikenley.com"
  domain_name        = "ai.ikenley.com"

  description = "AI-fueled pun generAItor"

}
