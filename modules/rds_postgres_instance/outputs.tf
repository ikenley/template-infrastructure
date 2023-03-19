resource "aws_ssm_parameter" "db_instance_address" {
  name  = "${local.output_prefix}/db_instance_address"
  type  = "SecureString"
  value = module.db.db_instance_address

  tags = local.tags
}

resource "aws_ssm_parameter" "db_instance_port" {
  name  = "${local.output_prefix}/db_instance_port"
  type  = "SecureString"
  value = module.db.db_instance_port

  tags = local.tags
}

resource "aws_ssm_parameter" "db_instance_name" {
  name  = "${local.output_prefix}/db_instance_name"
  type  = "SecureString"
  value = module.db.db_instance_name

  tags = local.tags
}

resource "aws_ssm_parameter" "db_instance_username" {
  name  = "${local.output_prefix}/db_instance_username"
  type  = "SecureString"
  value = module.db.db_instance_username

  tags = local.tags
}

resource "aws_ssm_parameter" "db_instance_password" {
  name  = "${local.output_prefix}/db_instance_password"
  type  = "SecureString"
  value = module.db.db_instance_password

  tags = local.tags
}

resource "aws_ssm_parameter" "db_instance_endpoint" {
  name  = "${local.output_prefix}/db_instance_endpoint"
  type  = "SecureString"
  value = module.db.db_instance_endpoint

  tags = local.tags
}

resource "aws_ssm_parameter" "db_instance_id" {
  name  = "${local.output_prefix}/db_instance_id"
  type  = "SecureString"
  value = module.db.db_instance_id

  tags = local.tags
}

resource "aws_ssm_parameter" "security_group_arn" {
  name  = "${local.output_prefix}/security_group_arn"
  type  = "SecureString"
  value = module.security_group.security_group_arn

  tags = local.tags
}

resource "aws_ssm_parameter" "security_group_id" {
  name  = "${local.output_prefix}/security_group_id"
  type  = "SecureString"
  value = module.security_group.security_group_id

  tags = local.tags
}

# resource "aws_ssm_parameter" "main_connection_string" {
#   name  = "/${var.name}/main-connection-string"
#   type  = "SecureString"
#   value = "Host=${module.db.this_db_instance_address};Port=5432;Database=${var.default_db_name};Username=${var.app_username};Password=${random_password.app_user.result}"

#   tags = local.tags
# }