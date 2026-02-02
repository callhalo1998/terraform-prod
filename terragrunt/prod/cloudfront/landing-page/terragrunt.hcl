terraform {
  source = "../../../../terraform/cloudfront/distribution"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "cloudfront_function" {
  config_path = "../cloudfront-function"
}

inputs = {
  create_distribution = true
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = false
  # aliases             = ["www..io"]
  custom_error_response = [
    {
      error_code            = 403
      response_page_path    = "/index.html"
      response_code         = 200
      error_caching_min_ttl = 0
    },
    {
      error_code            = 404
      response_page_path    = "/index.html"
      response_code         = 200
      error_caching_min_ttl = 0
    }
  ]

  oac_name            = "oac-prod--landing-page"

  origin = [
    {
      domain_name         = "dev--landing-page.s3.eu-west-3.amazonaws.com"
      origin_id           = "s3-origin"
      connection_attempts = 3
      connection_timeout  = 10
    }
  ]

  default_cache_behavior = {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    use_forwarded_values   = true
    query_string          = true
    cookies_forward       = "all"
    compress             = false
    function_associations = [
      {
        event_type   = "viewer-request"
        function_arn = dependency.cloudfront_function.outputs.cloudfront_function_arn
      }
    ]
  }

  # viewer_certificate = {
  #   acm_certificate_arn            = "arn:aws:acm:us-east-1::certificate/5232fd12-84d0-4f7e-8d1f-c12e9b76cb54"
  #   cloudfront_default_certificate = false
  #   ssl_support_method             = "sni-only"
  #   minimum_protocol_version       = "TLSv1.2_2021"
  # }
}