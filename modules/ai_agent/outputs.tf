#------------------------------------------------------------------------------
# rds.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "rds_cluster_arn" {
  provider = aws.primary
  name     = "${local.output_prefix}/rds_cluster_arn"
  type     = "String"
  value    = aws_rds_cluster.this.arn
}

resource "aws_ssm_parameter" "rds_cluster_id" {
  provider = aws.primary
  name     = "${local.output_prefix}/rds_cluster_id"
  type     = "String"
  value    = aws_rds_cluster.this.id
}

resource "aws_ssm_parameter" "rds_cluster_primary_instance_arn" {
  provider = aws.primary
  name     = "${local.output_prefix}/rds_cluster_primary_instance_arn"
  type     = "String"
  value    = aws_rds_cluster_instance.this.arn
}

resource "aws_ssm_parameter" "rds_cluster_primary_instance_id" {
  provider = aws.primary
  name     = "${local.output_prefix}/rds_cluster_primary_instance_id"
  type     = "String"
  value    = aws_rds_cluster_instance.this.id
}

resource "aws_ssm_parameter" "rds_cluster_writer_domain" {
  provider = aws.primary
  name     = "${local.output_prefix}/rds_cluster_writer_domain"
  type     = "String"
  value    = aws_route53_record.rds_kb_writer.name
}

resource "aws_ssm_parameter" "rds_cluster_reader_domain" {
  provider = aws.primary
  name     = "${local.output_prefix}/rds_cluster_reader_domain"
  type     = "String"
  value    = aws_route53_record.rds_kb_reader.name
}

resource "aws_ssm_parameter" "rds_cluster_security_group_arn" {
  provider = aws.primary
  name     = "${local.output_prefix}/rds_cluster_security_group_arn"
  type     = "String"
  value    = aws_security_group.rds_kb.arn
}

resource "aws_ssm_parameter" "rds_cluster_security_group_id" {
  provider = aws.primary
  name     = "${local.output_prefix}/rds_cluster_security_group_id"
  type     = "String"
  value    = aws_security_group.rds_kb.id
}

resource "aws_ssm_parameter" "bedrock_user_secret_arn" {
  provider = aws.primary
  name     = "${local.output_prefix}/bedrock_user_secret_arn"
  type     = "String"
  value    = aws_secretsmanager_secret.bedrock_user.arn
}

resource "aws_ssm_parameter" "bedrock_user_secret_id" {
  provider = aws.primary
  name     = "${local.output_prefix}/bedrock_user_secret_id"
  type     = "String"
  value    = aws_secretsmanager_secret.bedrock_user.id
}

#------------------------------------------------------------------------------
# regional.tf
#------------------------------------------------------------------------------

output "agent_id" {
  value = module.regional_primary.agent_id
}

output "agent_alias_current_id" {
  value = module.regional_primary.agent_alias_current_id
}
