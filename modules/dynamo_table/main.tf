
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
# DynamoDB table
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

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_index

    content {
      name               = global_secondary_index.value["name"]
      write_capacity     = global_secondary_index.value["write_capacity"]
      read_capacity      = global_secondary_index.value["read_capacity"]
      hash_key           = global_secondary_index.value["hash_key"]
      range_key          = global_secondary_index.value["range_key"]
      projection_type    = global_secondary_index.value["projection_type"]
      non_key_attributes = global_secondary_index.value["non_key_attributes"]
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

resource "aws_iam_role_policy_attachment" "dynamo_read_write_attach" {
  count = length(var.role_names)

  role       = var.role_names[count.index]
  policy_arn = aws_iam_policy.dynamo_policy.arn
}
