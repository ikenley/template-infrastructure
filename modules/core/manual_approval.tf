#-------------------------------------------------------------------------------
# Manual Approval step
#-------------------------------------------------------------------------------

locals {
  manual_approval_id     = "${var.namespace}-${var.env}-manual-approve"
  manual_approval_sfn_id = "${local.manual_approval_id}-sfn"
}

module "manual_approval" {
  source = "../manual_approval"

  namespace = var.namespace
  env       = var.env
  project   = "core"
  is_prod   = var.is_prod

  ses_email_addresses = [var.ses_email_address]

  sns_topic_arns = [aws_sns_topic.manual_approval.arn]

}

resource "aws_sns_topic" "manual_approval" {
  name = "${local.id}-manual-approval"

  kms_master_key_id = "alias/aws/sns"
}

# TODO make this a for each
resource "aws_sns_topic_subscription" "manual_approval" {
  topic_arn = aws_sns_topic.manual_approval.arn
  protocol  = "email"
  endpoint  = var.ses_email_address
}
