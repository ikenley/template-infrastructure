
locals {
  agent_resource_role_arn  = var.create_globals ? aws_iam_role.bedrock_agent[0].arn : var.agent_resource_role_arn
  agent_resource_role_name = var.create_globals ? aws_iam_role.bedrock_agent[0].name : var.agent_resource_role_name
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
    actions = ["bedrock:InvokeModel"]
    resources = [
      "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}::foundation-model/${local.foundation_model}",
    ]
  }
}

resource "aws_iam_role" "bedrock_agent" {
  count              = var.create_globals ? 1 : 0
  assume_role_policy = data.aws_iam_policy_document.bedrock_agent_trust.json
  name_prefix        = "AmazonBedrockExecutionRoleForAgents_"
}

resource "aws_iam_role_policy" "bedrock_agent" {
  count  = var.create_globals ? 1 : 0
  policy = data.aws_iam_policy_document.bedrock_agent_policy.json
  role   = local.agent_resource_role_name
}
