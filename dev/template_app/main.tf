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
  env = "dev"

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

  code_pipeline_s3_bucket_name = data.terraform_remote_state.core.outputs.code_pipeline_s3_bucket_name
  source_full_repository_id = "ikenley/template-application"
  source_branch_name = "main"
  codestar_connection_arn = "arn:aws:codestar-connections:us-east-1:924586450630:connection/73e9e607-3dc4-4a4d-9f81-a82c0030de6d"


  tags = {
    Environment = "dev"
  }
}

module "db" {
  source = "../../modules/rds_postgres_instance"

  name = "template-app"
  env = "dev"
  is_prod = false

  vpc_id           = data.terraform_remote_state.core.outputs.vpc_id
  vpc_cidr         = data.terraform_remote_state.core.outputs.vpc_cidr
  azs              = data.terraform_remote_state.core.outputs.azs
  public_subnets   = data.terraform_remote_state.core.outputs.public_subnets
  private_subnets  = data.terraform_remote_state.core.outputs.private_subnets
  database_subnets = data.terraform_remote_state.core.outputs.database_subnets

  domain_name   = "antig-one-rav.com"
  dns_subdomain = "template-app-dev"

  default_db_name = "template_app"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  max_allocated_storage = 50
  app_username = "template_app_user"

  tags = {
    Environment = "dev"
  }
}