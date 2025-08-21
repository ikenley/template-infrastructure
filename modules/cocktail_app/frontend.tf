# ------------------------------------------------------------------------------
# Front-end: Static React application on S3 behind Cloudfront CDN
# ------------------------------------------------------------------------------

module "frontend" {
  source = "../static_s3_website"

  namespace    = var.namespace
  env          = var.env
  is_prod      = var.is_prod
  project_name = var.project_name

  parent_domain_name     = var.parent_domain_name
  domain_name            = var.domain_name
  create_acm_certificate = false
  acm_certificate_arn    = module.acm_certificate.certificate_arn

  path_prefix = "cocktail/"

  logs_bucket_name = data.aws_ssm_parameter.logs_s3_bucket_name.value

  # Configure API Gateway origin
  additional_origins = {
    "api-gateway" = {
      domain_name  = replace(module.api_lambda.api_gateway_api_endpoint, "https://", "")
      path_pattern = "/cocktail/api/*"
    }
  }

  tags = var.tags
}



