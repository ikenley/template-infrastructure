# ------------------------------------------------------------------------------
# Front-end: Static React application on S3 behind Cloudfront CDN
# ------------------------------------------------------------------------------

module "frontend" {
  source = "../static_s3_website"

  name          = var.name
  env           = var.env
  is_prod       = var.is_prod
  domain_name   = var.domain_name
  dns_subdomain = var.dns_subdomain

  tags = var.tags
}
