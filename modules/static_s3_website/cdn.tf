

locals {
  s3_origin_id         = "static-s3-site"
  index_html_functions = var.create_index_html_function ? ["dummy_placeholder"] : []

  acm_certificate_arn = var.create_acm_certificate ? module.acm_certificate[0].certificate_arn : var.acm_certificate_arn

  viewer_request_function_arn = (
    var.enable_blue_green ? aws_cloudfront_function.blue_green[0].arn :
    var.viewer_request_function_arn != null ? var.viewer_request_function_arn :
    var.create_index_html_function ? aws_cloudfront_function.index_html[0].arn :
    null
  )
  viewer_request_functions = local.viewer_request_function_arn != null ? ["assoc"] : []
}


resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.s3_origin_id
  }

  dynamic "origin" {
    for_each = var.additional_origins

    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.key
      custom_origin_config {
        http_port              = "80"
        https_port             = "443"
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Managed by Terraform"
  default_root_object = var.enable_blue_green ? null : "${var.path_prefix}index.html"

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = var.enable_blue_green ? "/index.html" : "/${var.path_prefix}index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = var.enable_blue_green ? "/index.html" : "/${var.path_prefix}index.html"
  }

  logging_config {
    include_cookies = false
    bucket          = "${var.logs_bucket_name}.s3.amazonaws.com"
    prefix          = replace(var.domain_name, ".", "_")
  }

  aliases = [var.domain_name]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    dynamic "function_association" {
      for_each = local.viewer_request_functions
      content {
        event_type   = "viewer-request"
        function_arn = local.viewer_request_function_arn
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.additional_origins

    content {
      path_pattern             = ordered_cache_behavior.value.path_pattern
      allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods           = ["GET", "HEAD"]
      target_origin_id         = ordered_cache_behavior.key
      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled
      origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # Managed-AllViewer

      # min_ttl                = 0
      # default_ttl            = 3600
      # max_ttl                = 86400
      compress               = true
      viewer_protocol_policy = "https-only"
    }

  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB"]
    }
  }

  tags = local.tags

  lifecycle {
    precondition {
      condition     = !(var.enable_blue_green && (var.viewer_request_function_arn != null || var.create_index_html_function))
      error_message = "enable_blue_green cannot be combined with viewer_request_function_arn or create_index_html_function."
    }
  }

  viewer_certificate {
    acm_certificate_arn            = local.acm_certificate_arn
    ssl_support_method             = "sni-only"
    cloudfront_default_certificate = false
  }
}


module "acm_certificate" {
  count = var.create_acm_certificate ? 1 : 0

  source = "../acm_certificate"

  namespace    = var.namespace
  env          = var.env
  is_prod      = var.is_prod
  project_name = var.project_name

  domain_name      = var.domain_name
  route_53_zone_id = data.aws_route53_zone.this.zone_id

  tags = var.tags
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = local.id
  description                       = "Default Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "index_html" {
  count = var.create_index_html_function ? 1 : 0

  name    = "${local.id}-index-html"
  runtime = "cloudfront-js-2.0"
  comment = "Function which adds index.html to the request if needed"
  publish = true
  code    = <<EOF
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // Check whether the URI is missing a file name.
    if (uri.endsWith('/')) {
        request.uri += 'index.html';
    }
    // Check whether the URI is missing a file extension.
    else if (!uri.includes('.')) {
        request.uri += '/index.html';
    }

    return request;
}
EOF
}

resource "aws_cloudfront_key_value_store" "active_version" {
  count   = var.enable_blue_green ? 1 : 0
  name    = "${local.id}-active-version"
  comment = "Active deployment version for blue/green routing"
}

resource "aws_cloudfront_function" "blue_green" {
  count   = var.enable_blue_green ? 1 : 0
  name    = "${local.id}-blue-green"
  runtime = "cloudfront-js-2.0"
  comment = "Prepends active_version (and path_prefix) to all viewer requests"
  publish = true

  key_value_store_associations = [aws_cloudfront_key_value_store.active_version[0].arn]

  code = <<-EOF
import cf from 'cloudfront';
const kvsHandle = cf.kvs();

async function handler(event) {
    var request = event.request;
    let uri = request.uri;

    // Get version prefix if exists
    let activeVersion = "";
    try {
        activeVersion = "/" + await kvsHandle.get('active_version');
    } catch (err) {
        activeVersion = "";
    }

    // Add app URL prefix if it should exist and is missing
    const appUrlPrefix = "${var.path_prefix}";
    if (appUrlPrefix !== "" && !uri.startsWith(appUrlPrefix)) {
        uri = appUrlPrefix + uri;
    }

    // Append index.html at the end of the complete path if needed
    if (uri.endsWith('/')) {
        uri += 'index.html';
    } else if (!uri.includes('.')) {
        uri += '/index.html';
    }

    const fullPath = activeVersion + uri;
    request.uri = fullPath;

    return request;
}
  EOF
}
