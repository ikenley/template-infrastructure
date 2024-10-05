# ------------------------------------------------------------------------------
# S3 Bucket and CDN for hosting static content and/or websites
# ------------------------------------------------------------------------------

module "static_s3_website" {
  source = "../static_s3_website"

  namespace    = var.namespace
  env          = var.env
  project_name = "static"
  is_prod      = var.is_prod

  parent_domain_name = var.domain_name
  domain_name        = var.static_s3_domain
  logs_bucket_name   = module.s3_bucket_logs.s3_bucket_name

  path_prefix = ""

  create_index_html_function = true

  tags = local.tags
}
