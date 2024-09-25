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
}
