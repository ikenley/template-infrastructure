# ------------------------------------------------------------------------------
# revisit_prediction Lambda function
# ------------------------------------------------------------------------------

locals {
  revisit_prediction_id            = "${local.id}-revisit-prediction"
  revisit_prediction_output_prefix = "/${var.namespace}/${var.env}/revisit-prediction"
  pg_connection_parm_name          = "${local.output_prefix}/revisit_prediction/pg_connection"
}

# ------------------------------------------------------------------------------
# Revisit Prediction Lambda Function
# ------------------------------------------------------------------------------

module "revisit_prediction_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = local.revisit_prediction_id
  description   = "Check for Predictions that have a revisit_on date"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  publish       = true

  source_path = "${path.module}/revisit_prediction/src"

  vpc_subnet_ids         = var.private_subnets
  vpc_security_group_ids = [aws_security_group.revisit_prediction.id]
  attach_network_policy  = true

  environment_variables = {
    Serverless               = "Terraform"
    PG_CONNECTION_PARAM_NAME = local.pg_connection_parm_name
    SES_EMAIL_ADDRESS        = var.ses_email_address
  }

  tags = local.tags
}

resource "aws_security_group" "revisit_prediction" {
  name        = local.revisit_prediction_id
  description = "${local.revisit_prediction_id} sg"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.tags, {
    Name = local.revisit_prediction_id
  })
}

resource "aws_iam_policy" "revisit_prediction" {
  name = local.revisit_prediction_id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Ses",
        "Effect" : "Allow",
        "Action" : ["ses:SendEmail", "ses:SendRawEmail"],
        "Resource" : "${var.ses_email_arn}"
      },
      {
        "Sid" : "SSMDescribeParameters",
        "Effect" : "Allow",
        "Action" : [
          "ssm:DescribeParameters"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "SSMGetParameters",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
        ],
        "Resource" : [
          "arn:aws:ssm:*:*:parameter${local.pg_connection_parm_name}"
        ]
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "revisit_prediction" {
  role       = module.revisit_prediction_lambda.lambda_role_name
  policy_arn = aws_iam_policy.revisit_prediction.arn
}

module "revisit_prediction_eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "1.4.0"

  #bus_name = "${var.namespace}-bus"
  create_bus = false

  rules = {
    predictions = {
      name                = "daily-revisit-predictions"
      description         = "Check predictions once daily"
      schedule_expression = "cron(0 10 ? * * *)"
      enabled             = true
    }
  }

  targets = {
    predictions = [
      {
        name = "trigger-revisit-prediction-function"
        arn  = module.revisit_prediction_lambda.lambda_function_arn
      }
    ]
  }

  tags = var.tags
}

resource "aws_lambda_permission" "allow_revisit_prediction_eventbridge" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.revisit_prediction_lambda.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.revisit_prediction_eventbridge.eventbridge_rule_arns["predictions"]
}
