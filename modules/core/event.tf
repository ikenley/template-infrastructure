#------------------------------------------------------------------------------
# Core EventBridge setup
#------------------------------------------------------------------------------

resource "aws_cloudwatch_event_bus" "main" {
  name = local.id

  tags = local.tags
}

#------------------------------------------------------------------------------
# Log all events to CloudWatch
# Based on: 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target
#------------------------------------------------------------------------------

locals {
  event_log_id = "${local.id}-event-log"
}

resource "aws_cloudwatch_event_rule" "event_log" {
  name        = local.event_log_id
  description = "Log all Events"

  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    account = [local.account_id]
  })
}

resource "aws_cloudwatch_event_target" "event_log" {
  event_bus_name = aws_cloudwatch_event_bus.main.name
  rule = aws_cloudwatch_event_rule.event_log.name
  arn  = aws_cloudwatch_log_group.event_log.arn
}

resource "aws_cloudwatch_log_group" "event_log" {
  name              = local.event_log_id
  retention_in_days = 30
}

data "aws_iam_policy_document" "event_log" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream"
    ]

    resources = [
      "${aws_cloudwatch_log_group.event_log.arn}:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.event_log.arn}:*:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "delivery.logs.amazonaws.com"
      ]
    }

    condition {
      test     = "ArnEquals"
      values   = [aws_cloudwatch_event_rule.event_log.arn]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "event_log" {
  policy_document = data.aws_iam_policy_document.event_log.json
  policy_name     = local.event_log_id
}

