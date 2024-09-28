#-------------------------------------------------------------------------------
# Knowledge Base service account role
# https://docs.aws.amazon.com/bedrock/latest/userguide/kb-permissions.html
#-------------------------------------------------------------------------------

locals {
  knowledge_base_role_arn  = var.create_globals ? aws_iam_role.knowledge_base[0].arn : var.knowledge_base_role_arn
  knowledge_base_role_name = var.create_globals ? aws_iam_role.knowledge_base[0].name : var.knowledge_base_role_name
}

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
  # Permissions to access Amazon Bedrock models
  # https://docs.aws.amazon.com/bedrock/latest/userguide/kb-permissions.html#kb-permissions-access-models
  statement {
    sid     = "BedrockInvokeModel"
    effect  = "Allow"
    actions = ["bedrock:InvokeModel"]
    resources = [
      data.aws_bedrock_foundation_model.kb.model_arn,
    ]
  }

  # Permissions to access your data sources
  # https://docs.aws.amazon.com/bedrock/latest/userguide/kb-permissions.html#kb-permissions-access-ds
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
    actions = ["s3:GetObject"]
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

  # Permissions to access your Amazon Aurora database cluster
  # https://docs.aws.amazon.com/bedrock/latest/userguide/kb-permissions.html#kb-permissions-rds
  statement {
    sid       = "RdsDescribe"
    effect    = "Allow"
    actions   = ["rds:DescribeDBClusters"]
    resources = [var.rds_cluster_arn]
  }

  statement {
    sid    = "DataAPI"
    effect = "Allow"
    actions = [
      "rds-data:BatchExecuteStatement",
      "rds-data:ExecuteStatement",
    ]
    resources = [var.rds_cluster_arn]
  }

  statement {
    sid       = "RdsSecretRead"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.bedrock_user_secret_arn]
  }

  # AWS KMS key
  # https://docs.aws.amazon.com/bedrock/latest/userguide/kb-permissions.html#kb-permissions-kms-ingestion
  # TODO
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

# resource "aws_iam_role_policy" "knowledge_base_open_search" {
#   count = var.create_globals ? 1 : 0

#   name = "${local.id}-kb-open-search"
#   role = local.knowledge_base_role_name
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action   = "aoss:APIAccessAll"
#         Effect   = "Allow"
#         Resource = aws_opensearchserverless_collection.knowledge_base.arn
#       }
#     ]
#   })
# }
