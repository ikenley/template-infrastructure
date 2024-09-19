
locals {
  agent_resource_role_arn  = var.create_globals ? aws_iam_role.bedrock_agent[0].arn : var.agent_resource_role_arn
  agent_resource_role_name = var.create_globals ? aws_iam_role.bedrock_agent[0].name : var.agent_resource_role_name

  knowledge_base_role_arn  = var.create_globals ? aws_iam_role.knowledge_base[0].arn : var.knowledge_base_role_arn
  knowledge_base_role_name = var.create_globals ? aws_iam_role.knowledge_base[0].name : var.knowledge_base_role_name
}


#-------------------------------------------------------------------------------
# Bedrock agent service role
#-------------------------------------------------------------------------------

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
      data.aws_bedrock_foundation_model.agent.model_arn,
    ]
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

#-------------------------------------------------------------------------------
# Knowledge Base service account role
#-------------------------------------------------------------------------------

data "aws_iam_policy_document" "knowledge_base_trust" {
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
      values   = ["arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"]
      variable = "AWS:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "knowledge_base_policy" {
  statement {
    sid     = "BedrockInvokeModel"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]
    resources = [
      data.aws_bedrock_foundation_model.kb.model_arn,
    ]
  }

  statement {
    sid     = "S3ListBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      data.aws_ssm_parameter.s3_knowledge_base_arn.value
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"

      values = [
        local.account_id
      ]
    }
  }

  statement {
    sid     = "S3GetObject"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "${data.aws_ssm_parameter.s3_knowledge_base_arn.value}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"

      values = [
        local.account_id
      ]
    }
  }
}

resource "aws_iam_role" "knowledge_base" {
  count = var.create_globals ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.knowledge_base_trust.json
  name               = "${local.id}-knowledge-base"
}

resource "aws_iam_role_policy" "knowledge_base" {
  count = var.create_globals ? 1 : 0

  name   = "${local.id}-knowledge-base"
  policy = data.aws_iam_policy_document.knowledge_base_policy.json
  role   = local.knowledge_base_role_name
}

resource "aws_iam_role_policy" "knowledge_base_open_search" {
  count = var.create_globals ? 1 : 0

  name = "${local.id}-kb-open-search"
  role = local.knowledge_base_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "aoss:APIAccessAll"
        Effect   = "Allow"
        Resource = aws_opensearchserverless_collection.knowledge_base.arn
      }
    ]
  })
}
