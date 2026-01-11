# ------------------------------------------------------------------------------
# Front-end: Static React application on S3 behind Cloudfront CDN
# ------------------------------------------------------------------------------

module "frontend" {
  source = "../static_s3_website"

  namespace    = var.namespace
  env          = var.env
  is_prod      = var.is_prod
  project_name = var.name

  parent_domain_name = var.domain_name
  domain_name        = "${var.dns_subdomain}.${var.domain_name}"

  create_acm_certificate = true

  logs_bucket_name = data.aws_ssm_parameter.logs_s3_bucket_name.value

  # Configure API Gateway origin
  additional_origins = {
    "api-gateway" = {
      domain_name  = replace(module.api_lambda.api_gateway_api_endpoint, "https://", "")
      path_pattern = "/api/*"
    }
  }

  tags = var.tags
}
