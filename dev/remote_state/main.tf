# ------------------------------------------------------------------------------
# Creates the S3 Bucket and DynamoDB table used for remote state
# ------------------------------------------------------------------------------

locals {
  tags = {
    Project = "template"
  }
}

terraform {
  required_version = ">= 0.14"

  backend "s3" {
    profile = "terraform-dev"
    region = "us-east-1"
    bucket = "924586450630-terraform-state"
    key    = "remote_state/terraform.tfstate"
  }
}

provider "aws" {
  profile = "terraform-dev"
  region = "us-east-1"
}

module "remote_state_backend" {
  source = "../../modules/remote_state"
  s3_bucket_suffix = "terraform-state"

  tags = local.tags
}