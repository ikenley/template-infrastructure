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
    key     = "efs/dev/terraform.tfstate.json"
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
  source = "../../modules/main_root"

  providers = {
    aws.primary  = aws.primary
    aws.failover = aws.failover
  }

  namespace = "ik"
  env       = "dev"
  is_prod   = false

  read_write_root_role_arns = [
    "arn:aws:iam::924586450630:role/ik-dev-ec2-demo-mount-target"
  ]

  demo_app_access_point_role_arns = [
    "arn:aws:iam::924586450630:role/ik-dev-ec2-demo-access-point",
    "arn:aws:iam::924586450630:role/ik-dev-efs-ecs-demo-task-role"
  ]

}

module "ec2_demo" {
  source = "../../modules/ec2_demo"

  providers = {
    aws.primary  = aws.primary
    aws.failover = aws.failover
  }

  namespace = "ik"
  env       = "dev"
  is_prod   = false

  file_system_id  = module.main.primary_file_system_id
  access_point_id = module.main.demo_app_access_point_id
}

module "ecs_demo" {
  source = "../../modules/ecs_demo"

  providers = {
    aws.primary  = aws.primary
    aws.failover = aws.failover
  }

  namespace = "ik"
  env       = "dev"
  is_prod   = false

  file_system_id  = module.main.primary_file_system_id
  access_point_id = module.main.demo_app_access_point_id
}
