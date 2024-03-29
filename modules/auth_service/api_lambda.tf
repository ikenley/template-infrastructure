# ------------------------------------------------------------------------------
# Front-end: Static React application on S3 behind Cloudfront CDN
# ------------------------------------------------------------------------------

locals {
  api_domain_name = "api.${var.domain_name}"
}

module "api_lambda" {
  source = "../api_lambda"

  namespace    = var.namespace
  env          = var.env
  is_prod      = var.is_prod
  project_name = var.project_name

  git_repo   = var.git_repo
  git_branch = var.git_branch

  parent_domain_name = var.parent_domain_name
  domain_name      = local.api_domain_name

  aws_lb_listener_rule_priority = 12500

  image_uri = "924586450630.dkr.ecr.us-east-1.amazonaws.com/ik-dev-auth-api:b7aecb7"
  lambda_description = var.description
  lambda_timeout = 30
  lambda_memory_size = 1024

  environment_variables = {
    APP_ENV = var.env
    BASE_DOMAIN = var.parent_domain_name
    CONFIG_SSM_PARAM_NAME = aws_ssm_parameter.lambda_config.name
  }

  tags = var.tags
}

resource "aws_iam_policy" "api_lambda" {
  name        = "${local.id}-lambda"
  path        = "/"

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
        Sid: "AllowCognito", 
        Action = ["cognito-idp:AdminInitiateAuth"],
        Effect = "Allow"
        Resource = ["*"] # TODO narrow scope
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_lambda" {
  role       = module.api_lambda.lambda_role_name
  policy_arn = aws_iam_policy.api_lambda.arn
}
