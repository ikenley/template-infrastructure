#------------------------------------------------------------------------------
# Lambda function
#------------------------------------------------------------------------------

resource "aws_lambda_function" "this" {
  function_name = local.id
  role          = aws_iam_role.lambda.arn

  # Placeholder image uri
  image_uri    = "924586450630.dkr.ecr.us-east-1.amazonaws.com/ik-dev-ai-lambda-test:0.0.6"
  package_type = "Image"

  #source_code_hash = data.archive_file.lambda.output_base64sha256

  #runtime = "nodejs16.x"

  environment {
    variables = {
      foo = "bar"
    }
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
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
}
