#------------------------------------------------------------------------------
# CodeBuild status notifications via EventBridge -> SNS
#------------------------------------------------------------------------------

locals {
  codebuild_status_sns_id = "${local.id}-codebuild-status"
}

resource "aws_sns_topic" "codebuild_status" {
  name = local.codebuild_status_sns_id

  kms_master_key_id = "alias/aws/sns"

  tags = local.tags
}

data "aws_iam_policy_document" "codebuild_status_sns" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.codebuild_status.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "codebuild_status" {
  arn    = aws_sns_topic.codebuild_status.arn
  policy = data.aws_iam_policy_document.codebuild_status_sns.json
}

resource "aws_sns_topic_subscription" "codebuild_status" {
  for_each = toset(var.codebuild_status_emails)

  topic_arn = aws_sns_topic.codebuild_status.arn
  protocol  = "email"
  endpoint  = each.value
}

#------------------------------------------------------------------------------
# EventBridge rule on the default bus — CodeBuild state changes
#------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "codebuild_status" {
  name        = local.codebuild_status_sns_id
  description = "Capture CodeBuild FAILED/SUCCEEDED for projects in namespace ${var.namespace}"

  event_pattern = jsonencode({
    source      = ["aws.codebuild"]
    detail-type = ["CodeBuild Build State Change"]
    detail = {
      build-status = ["FAILED", "SUCCEEDED"]
      project-name = [{ prefix = var.namespace }]
    }
  })

  tags = local.tags
}

resource "aws_cloudwatch_event_target" "codebuild_status" {
  rule = aws_cloudwatch_event_rule.codebuild_status.name
  arn  = aws_sns_topic.codebuild_status.arn
}
