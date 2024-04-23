#------------------------------------------------------------------------------
# Lambda function
#------------------------------------------------------------------------------

resource "aws_lambda_function" "this" {
  function_name = local.id
  description   = var.lambda_description
  role          = aws_iam_role.lambda.arn

  # Placeholder image uri
  image_uri    = var.image_uri
  package_type = "Image"

  image_config {
    command = var.lambda_image_command
  }

  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory_size

  environment {
    variables = var.environment_variables
  }

  vpc_config {
    subnet_ids         = local.private_subnets
    security_group_ids = [aws_security_group.api_lambda.id]
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

resource "aws_iam_role" "lambda" {
  name = local.id

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

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

resource "aws_iam_policy" "lambda" {
  name        = local.id
  path        = "/"
  description = "Lambda execution policy for ${local.id}"

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
      }
    ]
  })
}
