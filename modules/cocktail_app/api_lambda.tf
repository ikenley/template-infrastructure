# ------------------------------------------------------------------------------
# Front-end: Static React application on S3 behind Cloudfront CDN
# ------------------------------------------------------------------------------

module "api_lambda" {
  source = "../api_lambda"

  namespace    = var.namespace
  env          = var.env
  is_prod      = var.is_prod
  project_name = "cocktail-api"

  git_repo   = var.git_repo
  git_branch = var.git_branch

  parent_domain_name     = var.parent_domain_name
  domain_name            = var.domain_name
  create_acm_certificate = false
  acm_certificate_arn    = module.acm_certificate.certificate_arn

  image_uri          = "924586450630.dkr.ecr.us-east-1.amazonaws.com/ik-dev-ai-lambda:da35cbb"
  lambda_description = var.description
  lambda_timeout     = 30
  lambda_memory_size = 1024

  environment_variables = {
    APP_ENV               = var.env
    BASE_DOMAIN           = var.parent_domain_name
    CONFIG_SSM_PARAM_NAME = aws_ssm_parameter.lambda_config.name

    AUTHORIZED_EMAILS = data.aws_ssm_parameter.authorized_emails.value
  }

  tags = var.tags
}

# ACM certificate
data "aws_route53_zone" "this" {
  name         = "${var.parent_domain_name}."
  private_zone = false
}

module "acm_certificate" {
  source = "../acm_certificate"

  namespace    = var.namespace
  env          = var.env
  is_prod      = var.is_prod
  project_name = var.project_name

  domain_name      = var.domain_name
  route_53_zone_id = data.aws_route53_zone.this.zone_id

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
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_lambda" {
  role       = module.api_lambda.lambda_role_name
  policy_arn = aws_iam_policy.api_lambda.arn
}

