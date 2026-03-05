# ------------------------------------------------------------------------------
# Custom domain name > CloudFront distribution > API Gateway > Lambda function
# ------------------------------------------------------------------------------

module "api_lambda" {
  source = "../api_lambda"

  namespace    = var.namespace
  env          = var.env
  is_prod      = var.is_prod
  project_name = var.project_name

  git_repo   = var.git_repo
  git_branch = var.git_branch

  parent_domain_name = var.parent_domain_name
  domain_name        = var.domain_name

  aws_lb_listener_rule_priority = 12500

  image_uri          = "924586450630.dkr.ecr.us-east-1.amazonaws.com/ik-dev-auth-api:b7aecb7"
  lambda_description = var.description
  lambda_timeout     = 30
  lambda_memory_size = 1024

  environment_variables = {
    APP_ENV                = var.env
    BASE_DOMAIN            = var.parent_domain_name
    CONFIG_SSM_PARAM_NAME  = aws_ssm_parameter.lambda_config.name
    USER_TABLE_NAME        = aws_dynamodb_table.user.name
    OAUTH_STATE_TABLE_NAME = aws_dynamodb_table.oauth_state.name
  }

  create_acm_certificate = true

  tags = var.tags
}

resource "aws_iam_policy" "api_lambda" {
  name = "${local.id}-lambda"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
        ]
        Effect   = "Allow"
        Resource = [aws_ssm_parameter.lambda_config.arn]
      },
      {
        Sid : "AllowCognito",
        Action   = ["cognito-idp:AdminInitiateAuth"],
        Effect   = "Allow"
        Resource = ["*"] # TODO narrow scope
      },
      {
        "Sid" : "AccessTableAllIndexesOnBooks",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:ConditionCheckItem"
        ],
        "Resource" : [
          "${aws_dynamodb_table.user.arn}",
          "${aws_dynamodb_table.user.arn}/index/*",
          "${aws_dynamodb_table.oauth_state.arn}",
          "${aws_dynamodb_table.oauth_state.arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_lambda" {
  role       = module.api_lambda.lambda_role_name
  policy_arn = aws_iam_policy.api_lambda.arn
}

# ------------------------------------------------------------------------------
# Dynamo DB tables for auth tables
# ------------------------------------------------------------------------------

locals {
  user_table        = "${local.id}-user"
  oauth_state_table = "${local.id}-oauth-state"
}

resource "aws_dynamodb_table" "user" {
  name = local.user_table

  billing_mode = "PAY_PER_REQUEST"

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  replica {
    region_name = "us-west-2"
  }

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }

  tags = merge(local.tags, {
    Name = local.user_table
  })
}

resource "aws_dynamodb_table" "oauth_state" {
  name = local.oauth_state_table

  billing_mode = "PAY_PER_REQUEST"

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  replica {
    region_name = "us-west-2"
  }

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = merge(local.tags, {
    Name = local.oauth_state_table
  })
}
