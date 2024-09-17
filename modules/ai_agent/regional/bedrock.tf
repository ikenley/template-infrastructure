#-------------------------------------------------------------------------------
# AWS Bedrock Agent
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagent_agent
#-------------------------------------------------------------------------------

locals {
  foundation_model = "anthropic.claude-3-5-sonnet-20240620-v1:0"
}

resource "aws_bedrockagent_agent" "this" {
  agent_name                  = local.id
  agent_resource_role_arn     = local.agent_resource_role_arn
  idle_session_ttl_in_seconds = 500
  foundation_model            = local.foundation_model

  instruction = "You are a task manager which looks up stats and sends summary emails. You have a sense of humor."
}

