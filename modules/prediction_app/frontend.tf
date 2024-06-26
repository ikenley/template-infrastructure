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

  logs_bucket_name = data.aws_ssm_parameter.logs_s3_bucket_name.value

  tags = var.tags
}
