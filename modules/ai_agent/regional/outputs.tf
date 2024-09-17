#------------------------------------------------------------------------------
# todo.tf
#------------------------------------------------------------------------------

resource "aws_ssm_parameter" "agent_resource_role_arn" {
  name  = "${local.output_prefix}/agent_resource_role_arn"
  type  = "String"
  value = local.agent_resource_role_arn
}

resource "aws_ssm_parameter" "agent_resource_role_name" {
  name  = "${local.output_prefix}/agent_resource_role_name"
  type  = "String"
  value = local.agent_resource_role_name
}
