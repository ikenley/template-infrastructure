#------------------------------------------------------------------------------
# Shared RDS Postgres instance
#------------------------------------------------------------------------------

module "rds_postgres" {
  source = "../rds_postgres_instance"

  tags      = var.tags
  namespace = var.namespace
  env       = var.env
  is_prod   = var.is_prod
  name      = "${var.name}-pg-01"

  vpc_id = module.vpc.vpc_id
  vpc_cidr = var.cidr
  database_subnets = module.vpc.database_subnets

  default_db_name = "core"
}
