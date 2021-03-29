################################################################################
# An RDS Postgres instance
# https://github.com/terraform-aws-modules/terraform-aws-rds/tree/v2.34.0/examples/complete-postgres
################################################################################

locals {
  tags = merge(var.tags, {
    Terraform = true
  })
}

################################################################################
# Supporting Resources
################################################################################

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "~> 2"

#   name = local.name
#   cidr = "10.99.0.0/18"

#   azs              = ["${local.region}a", "${local.region}b", "${local.region}c"]
#   public_subnets   = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]
#   private_subnets  = ["10.99.3.0/24", "10.99.4.0/24", "10.99.5.0/24"]
#   database_subnets = ["10.99.7.0/24", "10.99.8.0/24", "10.99.9.0/24"]

#   create_database_subnet_group = true

#   tags = local.tags
# }

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3"

  name        = var.name
  description = "Complete PostgreSQL example security group"
  vpc_id      = var.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = var.vpc_cidr
    },
  ]

  tags = local.tags
}

resource "random_password" "admin" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "admin_password" {
  name  = "/rds_admin/${var.name}-password"
  type  = "SecureString"
  value = random_password.admin.result

  tags = local.tags
}

################################################################################
# RDS Module
################################################################################

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.name

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "12.5"
  family               = "postgres12" # DB parameter group
  major_engine_version = "12"         # DB option group
  instance_class       = var.instance_class
  option_group_name    = "default:postgres-12"
  parameter_group_name = "postgres12"

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true

  iam_database_authentication_enabled = true

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  name     = var.default_db_name
  username = "admin_user"
  password = random_password.admin.result
  port     = 5432

  multi_az               = var.is_prod ? true : false
  subnet_ids             = var.database_subnets
  vpc_security_group_ids = [module.security_group.this_security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = 7
  skip_final_snapshot     = var.is_prod ? true : false
  deletion_protection     = var.is_prod ? true : false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_role_name                  = "${var.name}-monitoring-role"
  monitoring_interval                   = 60

  tags = local.tags
}

################################################################################
# Application user credentials
################################################################################

resource "random_password" "app_user" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "app_user_password" {
  name  = "/${var.name}/db-app-user-password"
  type  = "SecureString"
  value = random_password.app_user.result

  tags = local.tags
}

resource "aws_ssm_parameter" "main_connection_string" {
  name  = "/${var.name}/main-connection-string"
  type  = "SecureString"
  value = "Host=${module.db.this_db_instance_address};Database=${var.default_db_name};Username=${var.app_username};Password=${random_password.app_user.result}"

  tags = local.tags
}