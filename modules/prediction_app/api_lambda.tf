# ------------------------------------------------------------------------------
# Front-end: Static React application on S3 behind Cloudfront CDN
# ------------------------------------------------------------------------------

module "api_lambda" {
  source = "../api_lambda"

  namespace    = var.namespace
  env          = var.env
  is_prod      = var.is_prod
  project_name = var.name

  git_repo   = var.source_full_repository_id
  git_branch = var.source_branch_name

  parent_domain_name = var.domain_name 
  domain_name        = "api.${var.dns_subdomain}.${var.domain_name}"

  image_uri            = "924586450630.dkr.ecr.us-east-1.amazonaws.com/ik-test-prediction-lambda:3"
  lambda_image_command = ["PredictionApi::PredictionApi.LambdaEntryPoint::FunctionHandlerAsync"]
  lambda_description   = "Predictions app API Lambda"
  lambda_timeout       = 30
  lambda_memory_size   = 2048

  environment_variables = {
    APP_ENV                          = var.env
    BASE_DOMAIN                      = var.domain_name
    CONNECTION_STRING_SSM_PARAM_NAME = aws_ssm_parameter.prediction_app_user__connection_string.name
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
        "Sid" : "AllowSSMDescribeParameters",
        "Effect" : "Allow",
        "Action" : [
          "ssm:DescribeParameters"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "AllowSSMGetParameters",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        "Resource" : [
          aws_ssm_parameter.prediction_app_user__connection_string.arn,
          "arn:aws:ssm:*:${local.account_id}:parameter/prediction-app/app"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_lambda" {
  role       = module.api_lambda.lambda_role_name
  policy_arn = aws_iam_policy.api_lambda.arn
}
