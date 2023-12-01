# ------------------------------------------------------------------------------
# The "job runner" lambda function.
# Currently this is used to generate images
# ------------------------------------------------------------------------------

locals {
  job_runner_id = "${local.id}-job-runner"
}

resource "aws_lambda_function" "job_runner" {
  function_name = local.job_runner_id
  description   = "Job runner service for ${local.id}"
  role          = aws_iam_role.job_runner.arn

  # Placeholder image uri
  image_uri    = "924586450630.dkr.ecr.us-east-1.amazonaws.com/ik-dev-ai-lambda:da35cbb"
  package_type = "Image"

  timeout     = 30
  memory_size = 1024

  environment {
    variables = {
      APP_ENV               = var.env
      BASE_DOMAIN           = var.parent_domain_name
      CONFIG_SSM_PARAM_NAME = aws_ssm_parameter.lambda_config.name
      IMAGE_S3_BUCKET_NAME  = module.frontend.bucket_id
      FROM_EMAIL_ADDRESS    = data.aws_ssm_parameter.ses_email_address.value
      IMAGE_METADATA_TABLE_NAME = aws_dynamodb_table.image_metadata.name
    }
  }

  vpc_config {
    subnet_ids         = local.private_subnets
    security_group_ids = [aws_security_group.job_runner.id]
  }

  image_config {
    command = ["dist/index-job-runner.handler"]
  }

  lifecycle {
    ignore_changes = [
      image_uri
    ]
  }

  #   depends_on = [
  #     aws_iam_role_policy_attachment.lambda_logs,
  #     aws_cloudwatch_log_group.example,
  #   ]
}

resource "aws_iam_role" "job_runner" {
  name = local.job_runner_id

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "job_runner" {
  role       = aws_iam_role.job_runner.name
  policy_arn = aws_iam_policy.job_runner.arn
}

resource "aws_iam_policy" "job_runner" {
  name        = local.job_runner_id
  path        = "/"
  description = "Lambda execution policy for ${local.job_runner_id}"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowLogging",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AllowVpcAccess",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        "Resource" : "*"
      },
      {
        Action = [
          "ssm:GetParameter",
        ]
        Effect   = "Allow"
        Resource = [aws_ssm_parameter.lambda_config.arn]
      },
      {
        Sid = "ConsumeSQS"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Sid = "Bedrock"
        Action = [
          "bedrock:InvokeModel"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        "Sid" : "ListObjectsInBucket",
        "Effect" : "Allow",
        "Action" : ["s3:ListBucket"],
        "Resource" : ["arn:aws:s3:::${module.frontend.bucket_id}"]
      },
      {
        "Sid" : "AllObjectActions",
        "Effect" : "Allow",
        "Action" : "s3:PutObject",
        "Resource" : ["arn:aws:s3:::${module.frontend.bucket_id}/img/*"]
      },
      {
        Sid = "SesSend"
        Action = [
          "ses:SendEmail"
        ]
        Effect   = "Allow"
        Resource = "*"
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
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Lambda security group
#------------------------------------------------------------------------------

resource "aws_security_group" "job_runner" {
  name        = "${local.id}-job-runner"
  description = "Allow outbound to all"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value
}

resource "aws_security_group_rule" "job_runner_egress_https" {
  security_group_id = aws_security_group.job_runner.id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "job_runner_egress_pg" {
  security_group_id = aws_security_group.job_runner.id
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [data.aws_ssm_parameter.vpc_cidr.value]
}

#------------------------------------------------------------------------------
# SQS queue
#------------------------------------------------------------------------------

resource "aws_sqs_queue" "job_runner" {
  name = local.job_runner_id

  sqs_managed_sse_enabled = true

  tags = local.tags
}

resource "aws_lambda_event_source_mapping" "job_runner" {
  event_source_arn = aws_sqs_queue.job_runner.arn
  function_name    = aws_lambda_function.job_runner.arn
}
