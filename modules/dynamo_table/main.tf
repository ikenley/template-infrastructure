
# ------------------------------------------------------------------------------
# Cognito and other auth-adjacent resources
# ------------------------------------------------------------------------------

locals {
  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    is_prod     = var.is_prod
  })
}

data "aws_region" "current" {}

# ------------------------------------------------------------------------------
# DynamoDB table for storing one-time codes
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "this" {
  name = var.name

  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  hash_key       = var.hash_key
  range_key      = var.range_key

  dynamic "attribute" {
    for_each = var.attributes

    content {
      name = attribute.value["name"]
      type = attribute.value["type"]
    }
  }

  server_side_encryption {
    enabled = true
  }

  tags = local.tags
}

resource "aws_iam_policy" "dynamo_policy" {
  name = "${var.name}-dynamo-otc-policy"

  policy = templatefile("${path.module}/dynamo_policy.tpl", {
    dynamo_table_arn = aws_dynamodb_table.this.arn
  })
}

resource "aws_iam_role_policy_attachment" "cognito_admin" {
  role       = var.role_name
  policy_arn = aws_iam_policy.dynamo_policy.arn
}
