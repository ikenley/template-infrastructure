#------------------------------------------------------------------------------
# Shared Aurora Serverless v2 cluster
#------------------------------------------------------------------------------

module "aurora_serverless_v2" {
  source = "../aurora_serverless_v2"

  tags      = var.tags
  namespace = var.namespace
  env       = var.env
  is_prod   = var.is_prod
  name      = "${var.name}-aurora-01"

  database_name = "core"

  vpc_id           = module.vpc.vpc_id
  vpc_cidr         = var.cidr
  database_subnets = module.vpc.database_subnets

  snapshot_identifier = var.aurora_snapshot_identifier
}
