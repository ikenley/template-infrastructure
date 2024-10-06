#-------------------------------------------------------------------------------
# Bedrock agent service role
#-------------------------------------------------------------------------------

locals {
  agent_resource_role_arn  = var.create_globals ? aws_iam_role.bedrock_agent[0].arn : var.agent_resource_role_arn
  agent_resource_role_name = var.create_globals ? aws_iam_role.bedrock_agent[0].name : var.agent_resource_role_name

  rds_placeholders = var.create_rds_knowledge_base ? ["dummy_placeholder"] : []
}

data "aws_iam_policy_document" "bedrock_agent_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["bedrock.amazonaws.com"]
      type        = "Service"
    }
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }
    condition {
      test     = "ArnLike"
      values   = ["arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agent/*"]
      variable = "AWS:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "bedrock_agent_policy" {
  statement {
    sid     = "InvokeModel"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]
    resources = [
      data.aws_bedrock_foundation_model.agent.model_arn,
    ]
  }

  dynamic "statement" {
    for_each = local.rds_placeholders
    content {
      sid     = "RetrieveKnowledgeBase"
      effect  = "Allow"
      actions = ["bedrock:Retrieve"]
      resources = [
        aws_bedrockagent_knowledge_base.knowledge_base[0].arn
      ]
    }
  }
}

resource "aws_iam_role" "bedrock_agent" {
  count = var.create_globals ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.bedrock_agent_trust.json
  name               = "${local.id}-bedrock-execution"
}

resource "aws_iam_role_policy" "bedrock_agent" {
  count = var.create_globals ? 1 : 0

  name   = "${local.id}-bedrock-execution"
  policy = data.aws_iam_policy_document.bedrock_agent_policy.json
  role   = local.agent_resource_role_name
}
