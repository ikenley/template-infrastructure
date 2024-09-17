#------------------------------------------------------------------------------
# iam.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "agent_resource_role_arn" {
  name  = "${local.output_prefix}/agent_resource_role_arn"
  type  = "String"
  value = local.agent_resource_role_arn
}

output "agent_resource_role_arn" {
  value = local.agent_resource_role_arn
}

resource "aws_ssm_parameter" "agent_resource_role_name" {
  name  = "${local.output_prefix}/agent_resource_role_name"
  type  = "String"
  value = local.agent_resource_role_name
}

output "agent_resource_role_name" {
  value = local.agent_resource_role_name
}

#------------------------------------------------------------------------------
# bedrock.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "agent_arn" {
  name  = "${local.output_prefix}/agent_arn"
  type  = "String"
  value = aws_bedrockagent_agent.this.agent_arn
}

output "agent_arn" {
  value = aws_bedrockagent_agent.this.agent_arn
}

resource "aws_ssm_parameter" "agent_id" {
  name  = "${local.output_prefix}/agent_id"
  type  = "String"
  value = aws_bedrockagent_agent.this.agent_id
}

output "agent_id" {
  value = aws_bedrockagent_agent.this.agent_id
}

resource "aws_ssm_parameter" "agent_alias_current_id" {
  name  = "${local.output_prefix}/agent_alias_id"
  type  = "String"
  value = aws_bedrockagent_agent_alias.current.agent_alias_id
}

output "agent_alias_current_id" {
  value = aws_bedrockagent_agent_alias.current.agent_alias_id
}
