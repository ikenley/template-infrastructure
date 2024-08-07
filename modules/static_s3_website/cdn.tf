

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Managed by Terraform"
  default_root_object = "${var.path_prefix}index.html"

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/${var.path_prefix}index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/${var.path_prefix}index.html"
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

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.index_html.arn
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

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.static.arn
    ssl_support_method             = "sni-only"
    cloudfront_default_certificate = false
  }

  depends_on = [
    aws_acm_certificate_validation.this
  ]
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = local.id
  description                       = "Default Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "index_html" {
  name    = "${local.id}-index-html"
  runtime = "cloudfront-js-2.0"
  comment = "Function whihc adds index.html to the request if needed"
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
