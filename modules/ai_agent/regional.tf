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

  rds_cluster_arn         = aws_rds_cluster.this.arn
  bedrock_user_secret_arn = aws_secretsmanager_secret.bedrock_user.arn
}
