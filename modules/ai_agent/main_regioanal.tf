#-------------------------------------------------------------------------------
# Main regional resources
#-------------------------------------------------------------------------------

module "regional_primary" {
  source = "../main_regional"

  providers = {
    aws = aws.primary
  }

  namespace = var.namespace
  env       = var.env
  is_prod   = var.is_prod

  read_write_root_role_arns       = var.read_write_root_role_arns
  demo_app_access_point_role_arns = var.demo_app_access_point_role_arns

  file_system_arn = aws_efs_file_system.primary.arn
  file_system_id  = aws_efs_file_system.primary.id
}

module "regional_failover" {
  source = "../main_regional"

  providers = {
    aws = aws.failover
  }

  namespace = var.namespace
  env       = var.env
  is_prod   = var.is_prod

  read_write_root_role_arns       = var.read_write_root_role_arns
  demo_app_access_point_role_arns = var.demo_app_access_point_role_arns

  file_system_arn = aws_efs_file_system.failover.arn
  file_system_id  = aws_efs_file_system.failover.id
}
