# -----------------------------------------------------------------------------
# An RDS Postgres instance
# https://github.com/terraform-aws-modules/terraform-aws-rds/tree/v2.34.0/examples/complete-postgres
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  id            = "${var.namespace}-${var.env}-${var.name}"
  output_prefix = "/${var.namespace}/${var.env}/${var.name}"

  tags = merge(var.tags, {
    Environment = var.env
    is_prod     = var.is_prod
  })
}

# -----------------------------------------------------------------------------
# Supporting Resources
# -----------------------------------------------------------------------------



# -----------------------------------------------------------------------------
# RDS Module
# -----------------------------------------------------------------------------

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "5.6.0"

  identifier = local.id

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "14.12"
  family               = "postgres14" # DB parameter group
  major_engine_version = "14"         # DB option group
  instance_class       = var.instance_class
  option_group_name    = "default:postgres-14"
  parameter_group_name = "postgres14"

  allocated_storage                   = var.allocated_storage
  max_allocated_storage               = var.max_allocated_storage
  storage_encrypted                   = true
  iam_database_authentication_enabled = true

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name  = var.default_db_name
  username = "rds_admin"
  password = random_password.admin.result
  port     = 5432

  multi_az               = var.is_prod ? true : false
  create_db_subnet_group = true
  subnet_ids             = var.database_subnets
  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.is_prod ? false : true
  deletion_protection     = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_role_name                  = "${var.name}-monitoring-role"
  monitoring_interval                   = 60

  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3"

  name        = local.id
  description = "${local.id} RDS postgres"
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

  egress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = var.vpc_cidr
    },
  ]

  tags = merge(local.tags, {
    Name = local.id
  })
}

# -----------------------------------------------------------------------------
# Credentials
# -----------------------------------------------------------------------------

resource "random_password" "admin" {
  length           = 32
  override_special = "_"
}

# -----------------------------------------------------------------------------
# Setting up access to an Amazon S3 bucket
# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.Procedural.Importing.html
# -----------------------------------------------------------------------------

# resource "aws_iam_role" "etl_role" {
#   name = "${var.name}-rds-etl-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "rds.amazonaws.com"
#         }
#       }
#     ]
#   })

#   tags = local.tags
# }

# resource "aws_iam_policy" "etl_policy" {
#   name        = "${var.name}-rds-etl-policy"
#   description = "Policy enabling RDS s3 read writes"

#   policy = templatefile("${path.module}/rds_etl_policy.tpl", {
#     data_lake_s3_bucket_name = var.data_lake_s3_bucket_name
#   })
# }

# resource "aws_iam_role_policy_attachment" "aws_iam_policy_attach" {
#   role       = aws_iam_role.etl_role.name
#   policy_arn = aws_iam_policy.etl_policy.arn
# }

# resource "aws_db_instance_role_association" "s3_import" {
#   db_instance_identifier = module.db.this_db_instance_id
#   feature_name           = "s3Import"
#   role_arn               = aws_iam_role.etl_role.arn
# }

# resource "aws_db_instance_role_association" "s3_export" {
#   db_instance_identifier = module.db.this_db_instance_id
#   feature_name           = "s3Export"
#   role_arn               = aws_iam_role.etl_role.arn
# }

