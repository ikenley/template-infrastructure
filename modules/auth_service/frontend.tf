# ------------------------------------------------------------------------------
# Front-end: Static React application on S3 behind Cloudfront CDN
# ------------------------------------------------------------------------------

module "frontend" {
  source = "../static_s3_website"

  namespace    = var.namespace
  env          = var.env
  is_prod      = var.is_prod
  project_name = var.project_name

  parent_domain_name = var.parent_domain_name
  domain_name        = var.domain_name

  path_prefix = "${var.url_path_prefix}/"

  logs_bucket_name = data.aws_ssm_parameter.logs_s3_bucket_name.value

  create_acm_certificate = true

  # Configure API Gateway origin
  additional_origins = {
    "api-gateway" = {
      domain_name  = replace(module.api_lambda.api_gateway_api_endpoint, "https://", "")
      path_pattern = "/auth/api/*"
    }
  }

  tags = var.tags
}
