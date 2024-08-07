#-------------------------------------------------------------------------------
# Lambda Function which handles incoming approve/rejects
#-------------------------------------------------------------------------------

locals {
  receive_lambda_id = "${local.id}-receive"
}

module "receive_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.7.1"

  function_name = local.receive_lambda_id
  description   = "${local.id} receive manual approve callback"
  handler       = "lambda_function.handler"
  runtime       = "nodejs20.x"
  publish       = true
  timeout       = 30 # seconds

  source_path = "${path.module}/lambda/receive-lambda/src"

  environment_variables = {
    Serverless = "Terraform"
  }

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "receive_lambda_main" {
  role       = module.receive_lambda.lambda_role_name
  policy_arn = aws_iam_policy.receive_lambda_main.arn
}

resource "aws_iam_policy" "receive_lambda_main" {
  name        = "${local.receive_lambda_id}-main"
  path        = "/"
  description = "Main policy for ${local.receive_lambda_id}"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Logging",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*",
        "Effect" : "Allow"
      },
      {
        "Sid" : "sfn"
        "Action" : [
          "states:SendTaskFailure",
          "states:SendTaskSuccess"
        ],
        "Resource" : "*", # TODO restrict by arn
        "Effect" : "Allow"
      }
    ]
  })
}

