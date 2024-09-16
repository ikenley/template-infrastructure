#------------------------------------------------------------------------------
# todo.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "primary_file_system_id" {
  provider = aws.primary
  name     = "${local.output_prefix}/primary_file_system_id"
  type     = "String"
  value    = aws_efs_file_system.primary.id
}

output "primary_file_system_id" {
  value = aws_efs_file_system.primary.id
}

output "demo_app_access_point_id" {
  value = module.regional_primary.demo_app_access_point_id
}
