
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
      "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}::foundation-model/${local.foundation_model}",
    ]
  }
}

resource "aws_iam_role" "bedrock_agent" {
  count              = var.create_globals ? 1 : 0
  assume_role_policy = data.aws_iam_policy_document.bedrock_agent_trust.json
  name               = "${local.id}-bedrock-execution"
}

resource "aws_iam_role_policy" "bedrock_agent" {
  count  = var.create_globals ? 1 : 0
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
      values   = ["arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agent/*"]
      variable = "AWS:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "knowledge_base_policy" {
  statement {
    actions = ["bedrock:InvokeModel"]
    resources = [
      "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}::foundation-model/${local.foundation_model}",
    ]
  }
}
/* TODO add
https://blog.avangards.io/how-to-manage-an-amazon-bedrock-knowledge-base-using-terraform
resource "aws_iam_role_policy" "bedrock_kb_forex_kb_s3" {
  name = "AmazonBedrockS3PolicyForKnowledgeBase_${var.kb_name}"
  role = aws_iam_role.bedrock_kb_forex_kb.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3ListBucketStatement"
        Action   = "s3:ListBucket"
        Effect   = "Allow"
        Resource = aws_s3_bucket.forex_kb.arn
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = local.account_id
          }
      } },
      {
        Sid      = "S3GetObjectStatement"
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.forex_kb.arn}/*"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = local.account_id
          }
        }
      }
    ]
  })
}
*/

resource "aws_iam_role" "knowledge_base" {
  count              = var.create_globals ? 1 : 0
  assume_role_policy = data.aws_iam_policy_document.knowledge_base_trust.json
  name               = "${local.id}-knowledge-base"
}

resource "aws_iam_role_policy" "knowledge_base" {
  count  = var.create_globals ? 1 : 0
  policy = data.aws_iam_policy_document.knowledge_base_policy.json
  role   = local.knowledge_base_role_name
}
