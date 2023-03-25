
output "task_role_arn" {
  description = "The ARN of the Task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "task_role_name" {
  description = "The ARN of the Task role"
  value       = aws_iam_role.ecs_task_role.name
}

locals {
  pghost = data.aws_ssm_parameter.db_instance_address.value
  pgport = data.aws_ssm_parameter.db_instance_port.value
  pgdatabase = data.aws_ssm_parameter.db_database_name.value
}
resource "aws_ssm_parameter" "flyway_url" {
  name  = "${var.app_output_prefix}/flyway_url"
  type  = "SecureString"
  value = "jdbc:postgresql://${local.pghost}:${local.pgport}/${local.pgdatabase}"
}