#------------------------------------------------------------------------------
# Core EventBridge setup
#------------------------------------------------------------------------------

resource "aws_cloudwatch_event_bus" "main" {
  name = local.id

  tags = local.tags
}