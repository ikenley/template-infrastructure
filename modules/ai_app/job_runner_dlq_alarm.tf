#------------------------------------------------------------------------------
# Alerting when a job runner message lands in the dead letter queue
#------------------------------------------------------------------------------

locals {
  job_runner_dlq_alarm_id = "${local.job_runner_id}-dlq-alarm"
}

resource "aws_sns_topic" "job_runner_dlq" {
  name = local.job_runner_dlq_alarm_id

  tags = local.tags
}

data "aws_iam_policy_document" "job_runner_dlq_sns" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.job_runner_dlq.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "job_runner_dlq" {
  arn    = aws_sns_topic.job_runner_dlq.arn
  policy = data.aws_iam_policy_document.job_runner_dlq_sns.json
}

resource "aws_sns_topic_subscription" "job_runner_dlq" {
  for_each = toset(var.alarm_emails)

  topic_arn = aws_sns_topic.job_runner_dlq.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_cloudwatch_metric_alarm" "job_runner_dlq" {
  alarm_name        = local.job_runner_dlq_alarm_id
  alarm_description = "One or more ${local.job_runner_id} jobs failed and landed in the dead letter queue"

  namespace   = "AWS/SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"

  dimensions = {
    QueueName = aws_sqs_queue.job_runner_dlq.name
  }

  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1

  # SQS emits no datapoints for an empty queue, so missing data is the healthy case
  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.job_runner_dlq.arn]
  ok_actions    = [aws_sns_topic.job_runner_dlq.arn]

  tags = local.tags
}
