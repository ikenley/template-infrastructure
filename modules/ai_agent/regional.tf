#-------------------------------------------------------------------------------
# Main regional resources
#-------------------------------------------------------------------------------

module "regional_primary" {
  source = "./regional"

  providers = {
    aws = aws.primary
  }

  namespace = var.namespace
  env       = var.env
  is_prod   = var.is_prod
  project   = var.project

  create_globals = true

  create_rds_knowledge_base = var.create_rds_knowledge_base

  rds_cluster_arn         = var.create_rds_knowledge_base ? aws_rds_cluster.this[0].arn : ""
  bedrock_user_secret_arn = aws_secretsmanager_secret.bedrock_user.arn

  depends_on = [
    null_resource.db_setup_schema
  ]
}
