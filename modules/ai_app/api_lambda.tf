# ------------------------------------------------------------------------------
# Front-end: Static React application on S3 behind Cloudfront CDN
# ------------------------------------------------------------------------------

module "api_lambda" {
  source = "../api_lambda"

  namespace    = var.namespace
  env          = var.env
  is_prod      = var.is_prod
  project_name = "ai-api"

  git_repo   = var.git_repo
  git_branch = var.git_branch

  parent_domain_name = var.parent_domain_name
  domain_name        = "api.${var.domain_name}"

  image_uri          = "924586450630.dkr.ecr.us-east-1.amazonaws.com/ik-dev-ai-lambda:da35cbb"
  lambda_description = var.description
  lambda_timeout     = 30
  lambda_memory_size = 1024

  environment_variables = {
    APP_ENV                   = var.env
    BASE_DOMAIN               = var.parent_domain_name
    CONFIG_SSM_PARAM_NAME     = aws_ssm_parameter.lambda_config.name
    AUTHORIZED_EMAILS         = data.aws_ssm_parameter.authorized_emails.value
    JOB_QUEUE_URL             = aws_sqs_queue.job_runner.url
    IMAGE_METADATA_TABLE_NAME = aws_dynamodb_table.image_metadata.name
    STATE_FUNCTION_ARN        = data.aws_ssm_parameter.storybook_sfn_state_machine_arn.value
    BEDROCK_AGENT_ID          = data.aws_ssm_parameter.agent_id.value
    BEDROCK_AGENT_ALIAS_ID    = data.aws_ssm_parameter.agent_alias_id.value
  }

  tags = var.tags
}

resource "aws_iam_policy" "api_lambda" {
  name = "${local.id}-lambda"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "GetSSMParams"
        Action = [
          "ssm:GetParameter",
        ]
        Effect   = "Allow"
        Resource = [aws_ssm_parameter.lambda_config.arn]
      },
      {
        Sid = "SendSQSMessage"
        Action = [
          "sqs:SendMessage",
        ]
        Effect   = "Allow"
        Resource = [aws_sqs_queue.job_runner.arn]
      },
      {
        "Sid" : "AllowDynamoImageMetadata",
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
          aws_dynamodb_table.image_metadata.arn,
          "${aws_dynamodb_table.image_metadata.arn}/index/*"
        ]
      },
      {
        "Sid" : "AllowStepFunction",
        "Effect" : "Allow",
        "Action" : [
          "states:StartExecution"
        ],
        "Resource" : [data.aws_ssm_parameter.storybook_sfn_state_machine_arn.value]
      },
      {
        "Sid" : "InvokeBedrockAgent",
        "Effect" : "Allow",
        "Action" : [
          "bedrock:InvokeAgent"
        ],
        "Resource" : ["arn:aws:bedrock:*:${local.account_id}:agent-alias/${local.agent_id}/${local.agent_alias_id}"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_lambda" {
  role       = module.api_lambda.lambda_role_name
  policy_arn = aws_iam_policy.api_lambda.arn
}


#------------------------------------------------------------------------------
# Dynamo table for logging image metadata
#------------------------------------------------------------------------------

resource "aws_dynamodb_table" "image_metadata" {
  name         = "image_metadata"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "imageId"

  deletion_protection_enabled = true
  table_class                 = "STANDARD_INFREQUENT_ACCESS"

  attribute {
    name = "imageId"
    type = "S"
  }

  tags = local.tags
}
