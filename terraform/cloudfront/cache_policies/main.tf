terraform {
  backend "s3" {}
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

# ------------------------------------------------------------------------------  
# CACHE POLICY
# ------------------------------------------------------------------------------

resource "aws_cloudfront_cache_policy" "cache_policy" {
  name        = var.cache_policy_name
  comment     = var.cache_policy_comment
  default_ttl = var.cache_policy_default_ttl
  max_ttl     = var.cache_policy_max_ttl
  min_ttl     = var.cache_policy_min_ttl

  parameters_in_cache_key_and_forwarded_to_origin {

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    headers_config {
      header_behavior = var.headers_behavior

      dynamic "headers" {
        for_each = length(var.headers_items) > 0 ? [1] : []
        content {
          items = var.headers_items
        }
      }
    }

    query_strings_config {
      query_string_behavior = var.query_string_behavior

      dynamic "query_strings" {
        for_each = length(var.query_strings_items) > 0 ? [1] : []
        content {
          items = var.query_strings_items
        }
      }
    }

    cookies_config {
      cookie_behavior = var.cookie_behavior

      dynamic "cookies" {
        for_each = length(var.cookies_items) > 0 ? [1] : []
        content {
          items = var.cookies_items
        }
      }
    }
  }
}