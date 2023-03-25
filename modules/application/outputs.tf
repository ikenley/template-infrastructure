
output "task_role_arn" {
  description = "The ARN of the Task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "task_role_name" {
  description = "The ARN of the Task role"
  value       = aws_iam_role.ecs_task_role.name
}

locals {
  pghost = data.aws_ssm_parameter.db_instance_address
  pgport = data.aws_ssm_parameter.db_instance_port
  pgdatabase = data.aws_ssm_parameter.db_database_name
}
resource "aws_ssm_parameter" "flyway_url" {
  name  = "${local.output_prefix}/flyway_url"
  type  = "SecureString"
  value = "jdbc:postgresql://${local.pghost}:${local.pgport}/${local.pgdatabase}"
}