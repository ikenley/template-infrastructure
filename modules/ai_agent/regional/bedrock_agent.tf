#-------------------------------------------------------------------------------
# AWS Bedrock Agent + Action Group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/bedrockagent_agent
#-------------------------------------------------------------------------------

locals {
  agent_foundation_model = "anthropic.claude-3-5-sonnet-20240620-v1:0"
}

data "aws_bedrock_foundation_model" "agent" {
  model_id = local.agent_foundation_model
}

resource "aws_bedrockagent_agent" "this" {
  agent_name                  = local.id
  agent_resource_role_arn     = local.agent_resource_role_arn
  idle_session_ttl_in_seconds = 500
  foundation_model            = local.agent_foundation_model

  guardrail_configuration = [{
    guardrail_identifier = aws_bedrock_guardrail.default.guardrail_id
    guardrail_version    = aws_bedrock_guardrail_version.current.version
  }]

  instruction = "You are a task manager which looks up stats and sends summary emails. You have a sense of humor."
}

resource "aws_bedrockagent_agent_alias" "current" {
  agent_alias_name = "current"
  agent_id         = aws_bedrockagent_agent.this.agent_id
  description      = "Current alias"
}

#-------------------------------------------------------------------------------
# Action groups
# https://docs.aws.amazon.com/bedrock/latest/userguide/agents-action-create.html
#-------------------------------------------------------------------------------

resource "aws_bedrockagent_agent_action_group" "email_summary" {
  action_group_name          = "${local.id}-utility"
  agent_id                   = aws_bedrockagent_agent.this.agent_id
  agent_version              = "DRAFT"
  skip_resource_in_use_check = true

  action_group_executor {
    custom_control = "RETURN_CONTROL"
  }

  function_schema {
    member_functions {
      functions {
        name        = "SendSumaryEmail"
        description = "Sends an email with a summary of the conversation"
        parameters {
          map_block_key = "summary"
          type          = "string"
          description   = "A summary of the conversation thus far"
          required      = true
        }
      }
    }
  }
}

# Update agent whenever action group changes
# https://blog.avangards.io/how-to-manage-an-amazon-bedrock-agent-using-terraform
resource "null_resource" "prepare_email_summary_change" {
  triggers = {
    agent_state                      = sha256(jsonencode(aws_bedrockagent_agent.this))
    action_group_email_summary_state = sha256(jsonencode(aws_bedrockagent_agent_action_group.email_summary))
    #knowledge_base                   = sha256(jsonencode(aws_bedrockagent_knowledge_base.knowledge_base))
  }
  provisioner "local-exec" {
    command = <<EOF
aws bedrock-agent prepare-agent --agent-id ${aws_bedrockagent_agent.this.agent_id}
# aws bedrock-agent update-agent-alias \
# --agent-id ${aws_bedrockagent_agent.this.agent_id} \
# --agent-alias-id ${aws_bedrockagent_agent_alias.current.agent_alias_id} \
# --agent-alias-name ${aws_bedrockagent_agent_alias.current.agent_alias_name}
EOF
  }

  depends_on = [
    aws_bedrockagent_agent.this,
    aws_bedrockagent_agent_action_group.email_summary,
    #aws_bedrockagent_knowledge_base.knowledge_base
  ]
}
