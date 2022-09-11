# ------------------------------------------------------------------------------
# AWS Transfer Family SFTP
# Based on https://github.com/cloudposse/terraform-aws-transfer-sftp/
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  id = "${var.namespace}-${var.env}-sftp"

  enabled = var.spend_money

  tags = merge(var.tags, {
    Terraform   = true
    Environment = var.env
    is_prod     = var.is_prod
    module      = "transfer_sftp"
  })
}

locals {

  #   user_names = keys(var.sftp_users)

  #   user_names_map = {
  #     for user, val in var.sftp_users :
  #     user => merge(val, {
  #       s3_bucket_arn = lookup(val, "s3_bucket_name", null) != null ? "${local.s3_arn_prefix}${lookup(val, "s3_bucket_name")}" : one(data.aws_s3_bucket.landing[*].arn)
  #     })
  #   }
}

resource "aws_transfer_server" "this" {
  count = local.enabled ? 1 : 0

  identity_provider_type = "SERVICE_MANAGED"
  protocols              = ["SFTP"]
  domain                 = "S3"
  endpoint_type          = "PUBLIC"
  force_destroy          = false # TODO set to true for production
  security_policy_name   = "TransferSecurityPolicy-2022-03"
  logging_role           = aws_iam_role.logging.arn

  tags = local.tags
}

# Custom Domain
resource "aws_route53_record" "this" {
  count = local.enabled ? 1 : 0

  name    = var.domain_name
  zone_id = var.route_53_zone_id
  type    = "CNAME"
  ttl     = "300"

  records = [
    join("", aws_transfer_server.this[*].endpoint)
  ]
}

# ------------------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "logging" {
  name                = "${local.id}-logging"
  assume_role_policy  = data.aws_iam_policy_document.assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.logging.arn]

  tags = local.tags
}


data "aws_iam_policy_document" "logging" {
  statement {
    sid    = "CloudWatchAccessForAWSTransfer"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "logging" {
  name   = "${local.id}-logging"
  policy = data.aws_iam_policy_document.logging.json
}

# ------------------------------------------------------------------------------
# Users
# ------------------------------------------------------------------------------

# resource "aws_transfer_user" "default" {
#   for_each = local.enabled ? var.sftp_users : {}

#   server_id = join("", aws_transfer_server.default[*].id)
#   role      = aws_iam_role.s3_access_for_sftp_users[each.value.user_name].arn

#   user_name = each.value.user_name

#   home_directory_type = lookup(each.value, "home_directory_type", null) != null ? lookup(each.value, "home_directory_type") : (var.restricted_home ? "LOGICAL" : "PATH")
#   home_directory      = lookup(each.value, "home_directory", null) != null ? lookup(each.value, "home_directory") : (!var.restricted_home ? "/${lookup(each.value, "s3_bucket_name", var.s3_bucket_name)}" : null)

#   dynamic "home_directory_mappings" {
#     for_each = var.restricted_home ? (
#       lookup(each.value, "home_directory_mappings", null) != null ? lookup(each.value, "home_directory_mappings") : [
#         {
#           entry = "/"
#           # Specifically do not use $${Transfer:UserName} since subsequent terraform plan/applies will try to revert
#           # the value back to $${Tranfer:*} value
#           target = format("/%s/%s", lookup(each.value, "s3_bucket_name", var.s3_bucket_name), each.value.user_name)
#         }
#       ]
#     ) : toset([])

#     content {
#       entry  = lookup(home_directory_mappings.value, "entry")
#       target = lookup(home_directory_mappings.value, "target")
#     }
#   }

#   tags = module.this.tags
# }

# resource "aws_transfer_ssh_key" "default" {
#   for_each = local.enabled ? var.sftp_users : {}

#   server_id = join("", aws_transfer_server.default[*].id)

#   user_name = each.value.user_name
#   body      = each.value.public_key

#   depends_on = [
#     aws_transfer_user.default
#   ]
# }

# data "aws_iam_policy_document" "s3_access_for_sftp_users" {
#   for_each = local.enabled ? local.user_names_map : {}

#   statement {
#     sid    = "AllowListingOfUserFolder"
#     effect = "Allow"

#     actions = [
#       "s3:ListBucket"
#     ]

#     resources = [
#       each.value.s3_bucket_arn,
#     ]
#   }

#   statement {
#     sid    = "HomeDirObjectAccess"
#     effect = "Allow"

#     actions = [
#       "s3:PutObject",
#       "s3:GetObject",
#       "s3:DeleteObject",
#       "s3:DeleteObjectVersion",
#       "s3:GetObjectVersion",
#       "s3:GetObjectACL",
#       "s3:PutObjectACL"
#     ]

#     resources = [
#       var.restricted_home ? "${each.value.s3_bucket_arn}/${each.value.user_name}/*" : "${each.value.s3_bucket_arn}/*"
#     ]
#   }
# }

# module "iam_label" {
#   for_each = local.enabled ? local.user_names_map : {}

#   source  = "cloudposse/label/null"
#   version = "0.25.0"

#   attributes = ["transfer", "s3", each.value.user_name]

#   context = module.this.context
# }

# resource "aws_iam_policy" "s3_access_for_sftp_users" {
#   for_each = local.enabled ? local.user_names_map : {}

#   name   = module.iam_label[each.value.user_name].id
#   policy = data.aws_iam_policy_document.s3_access_for_sftp_users[each.value.user_name].json

#   tags = module.this.tags
# }

# resource "aws_iam_role" "s3_access_for_sftp_users" {
#   name = module.iam_label[each.value.user_name].id

#   assume_role_policy  = join("", data.aws_iam_policy_document.assume_role_policy[*].json)
#   managed_policy_arns = [aws_iam_policy.s3_access_for_sftp_users[each.value.user_name].arn]

#   tags = module.this.tags
# }
