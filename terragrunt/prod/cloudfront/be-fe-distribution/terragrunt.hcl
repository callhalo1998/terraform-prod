terraform {
  source = "../../../../terraform/cloudfront/distribution"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  create_distribution = true
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = false
  aliases             = ["www..io"]
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

  oac_name            = "oac-prod--fe"

  origin = [
    {
      domain_name         = "prod--frontend.s3.eu-west-3.amazonaws.com"
      origin_id           = "s3-origin"
      connection_attempts = 3
      connection_timeout  = 10
    },
    {
      domain_name         = "prod-api-alb-40607519.eu-west-3.elb.amazonaws.com"
      origin_id           = "prod-api-alb-40607519.eu-west-3.elb.amazonaws.com"
      connection_attempts = 3
      connection_timeout  = 10

      custom_origin_config = {
        http_port                = 80
        https_port               = 443
        origin_protocol_policy   = "http-only"
        origin_read_timeout      = 30
        origin_keepalive_timeout = 5
        origin_ssl_protocols     = ["TLSv1.2", "SSLv3", "TLSv1", "TLSv1.1"]
      }
    }
  ]

  ordered_cache_behavior = [
    #precedence 0
    {
      path_pattern             = "/api/*"
      use_forwarded_values     = true
      target_origin_id         = "prod-api-alb-40607519.eu-west-3.elb.amazonaws.com"
      viewer_protocol_policy   = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      use_forwarded_values   = true
      headers               = ["*"]
      query_string          = true
      cookies_forward       = "all"
      compress             = true
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
  }

  viewer_certificate = {
    acm_certificate_arn            = "arn:aws:acm:us-east-1::certificate/5232fd12-84d0-4f7e-8d1f-c12e9b76cb54"
    cloudfront_default_certificate = false
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}