# ------------------------------------------------------------------------------
# Configure the top-level domain for the project
# In this case, we just redirect to a github.io page
# Simplicity is good. We could do something more "correct" with CloudFront and S3
#   , but this is good enough for now.
# ------------------------------------------------------------------------------

resource "aws_cloudfront_function" "github_redirect" {
  name    = "${var.namespace}-${var.env}-ikenley-github-redirect"
  runtime = "cloudfront-js-2.0"
  comment = "Redirects all requests to https://ikenley.github.io/"
  publish = true
  code    = <<-EOF
    function handler(event) {
        return {
            statusCode: 301,
            statusDescription: "Moved Permanently",
            headers: {
                "location": {
                    value: "https://ikenley.github.io/"
                }
            }
        };
    }
  EOF
}

module "top_level_domain" {
  source = "../static_s3_website"

  namespace    = var.namespace
  env          = var.env
  project_name = "ikenley"
  is_prod      = var.is_prod

  parent_domain_name = var.domain_name
  domain_name        = var.domain_name
  logs_bucket_name   = module.s3_bucket_logs.s3_bucket_name

  path_prefix = ""

  create_index_html_function  = false
  viewer_request_function_arn = aws_cloudfront_function.github_redirect.arn

  create_acm_certificate = true

  tags = local.tags
}
