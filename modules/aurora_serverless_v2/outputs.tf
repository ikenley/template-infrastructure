output "cluster_endpoint" {
  description = "Writer endpoint for the Aurora cluster"
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint for the Aurora cluster"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "cluster_port" {
  description = "Port for the Aurora cluster"
  value       = aws_rds_cluster.this.port
}

output "cluster_database_name" {
  description = "Database name for the Aurora cluster"
  value       = aws_rds_cluster.this.database_name
}

output "security_group_id" {
  description = "Security group ID for the Aurora cluster"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "Security group ARN for the Aurora cluster"
  value       = aws_security_group.this.arn
}

#------------------------------------------------------------------------------
# SSM Parameters
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "cluster_endpoint" {
  name  = "${local.output_prefix}/cluster_endpoint"
  type  = "SecureString"
  value = aws_rds_cluster.this.endpoint

  tags = local.tags
}

resource "aws_ssm_parameter" "cluster_reader_endpoint" {
  name  = "${local.output_prefix}/cluster_reader_endpoint"
  type  = "SecureString"
  value = aws_rds_cluster.this.reader_endpoint

  tags = local.tags
}

resource "aws_ssm_parameter" "cluster_port" {
  name  = "${local.output_prefix}/cluster_port"
  type  = "SecureString"
  value = aws_rds_cluster.this.port

  tags = local.tags
}

resource "aws_ssm_parameter" "cluster_database_name" {
  name  = "${local.output_prefix}/cluster_database_name"
  type  = "String"
  value = var.database_name

  tags = local.tags
}

resource "aws_ssm_parameter" "master_username" {
  name  = "${local.output_prefix}/master_username"
  type  = "SecureString"
  value = aws_rds_cluster.this.master_username

  tags = local.tags
}

resource "aws_ssm_parameter" "master_password" {
  name  = "${local.output_prefix}/master_password"
  type  = "SecureString"
  value = random_password.master.result

  tags = local.tags
}

resource "aws_ssm_parameter" "security_group_id" {
  name  = "${local.output_prefix}/security_group_id"
  type  = "SecureString"
  value = aws_security_group.this.id

  tags = local.tags
}
