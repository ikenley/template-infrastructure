# ------------------------------------------------------------------------------
# Front-end: Static React application on S3 behind Cloudfront CDN
# ------------------------------------------------------------------------------

module "api_lambda" {
  source = "../api_lambda"

  namespace    = var.namespace
  env          = var.env
  is_prod      = var.is_prod
  project_name = "ai"

  git_repo   = var.git_repo
  git_branch = var.git_branch

  parent_domain_name = var.parent_domain_name
  domain_name      = "api.${var.domain_name}"

  tags = var.tags
}
