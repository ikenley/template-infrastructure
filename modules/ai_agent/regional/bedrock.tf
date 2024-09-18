#-------------------------------------------------------------------------------
# AWS Bedrock Agent + Action Group
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

  # TODO switch to RETURN_CONTROL
  # action_group_executor {
  #   custom_control = "RETURN_CONTROL"
  # }

  # TODO switch to RETURN_CONTROL
  action_group_executor {
    lambda = "arn:aws:lambda:us-east-1:924586450630:function:action-group-quick-start-rljn8-a1403"
  }

  function_schema {
    member_functions {
      functions {
        name        = "SendSumaryEmail"
        description = "Sends an email with a summary of the conversation"
        parameters {
          map_block_key = "emailAddress"
          type          = "string"
          description   = "The email address to send the summary to"
          required      = true
        }
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
  }
  provisioner "local-exec" {
    command = <<EOF
aws bedrock-agent prepare-agent --agent-id ${aws_bedrockagent_agent.this.agent_id}
aws bedrock-agent update-agent-alias \
--agent-id ${aws_bedrockagent_agent.this.agent_id} \
--agent-alias-id ${aws_bedrockagent_agent_alias.current.agent_alias_id} \
--agent-alias-name ${aws_bedrockagent_agent_alias.current.agent_alias_name}
EOF
  }

  depends_on = [
    aws_bedrockagent_agent.this,
    aws_bedrockagent_agent_action_group.email_summary
  ]
}
