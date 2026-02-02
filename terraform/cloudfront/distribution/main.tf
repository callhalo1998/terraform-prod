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
# Origin Access (S3 only)
# ------------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "this" {
  count = var.oac_name == null ? 0 : 1
  name                              = var.oac_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


# ------------------------------------------------------------------------------  
# Distribution
# ------------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "this" {
  count = var.create_distribution ? 1 : 0

  aliases                         = var.aliases
  comment                         = var.comment
  default_root_object             = var.default_root_object
  enabled                         = var.enabled
  http_version                    = var.http_version
  is_ipv6_enabled                 = var.is_ipv6_enabled
  price_class                     = var.price_class
  wait_for_deployment             = var.wait_for_deployment
  web_acl_id                      = var.web_acl_id
  tags = {
    Environment = var.environment
    Terraform   = "true"
  }

  dynamic "logging_config" {
    for_each = length(keys(var.logging_config)) == 0 ? [] : [var.logging_config]

    content {
      bucket          = logging_config.value["bucket"]
      prefix          = lookup(logging_config.value, "prefix", null)
      include_cookies = lookup(logging_config.value, "include_cookies", false)
    }
  }

  dynamic "origin" {
    for_each = var.origin

    content {
      domain_name              = origin.value.domain_name
      origin_id                = lookup(origin.value, "origin_id", origin.key)
      origin_access_control_id = (
        origin.value.origin_id == "s3-origin" && length(aws_cloudfront_origin_access_control.this) > 0
        ? aws_cloudfront_origin_access_control.this[0].id
        : null
      )
      origin_path              = lookup(origin.value, "origin_path", "")
      connection_attempts      = lookup(origin.value, "connection_attempts", null)
      connection_timeout       = lookup(origin.value, "connection_timeout", null)
      
      # VPC origin
      dynamic "vpc_origin_config" {
        for_each = lookup(origin.value, "vpc_origin_config", null) == null ? [] : [origin.value.vpc_origin_config]

        content {
          origin_keepalive_timeout = lookup(vpc_origin_config.value, "origin_keepalive_timeout", null)
          origin_read_timeout      = lookup(vpc_origin_config.value, "origin_read_timeout", null)
          vpc_origin_id            = vpc_origin_config.value.vpc_origin_id
        }
      }

      #Additional settings
      dynamic "custom_origin_config" {
        for_each = length(lookup(origin.value, "custom_origin_config", "")) == 0 ? [] : [lookup(origin.value, "custom_origin_config", "")]

        content {
          http_port                = custom_origin_config.value.http_port
          https_port               = custom_origin_config.value.https_port
          origin_protocol_policy   = custom_origin_config.value.origin_protocol_policy
          origin_ssl_protocols     = custom_origin_config.value.origin_ssl_protocols
          origin_keepalive_timeout = lookup(custom_origin_config.value, "origin_keepalive_timeout", null)
          origin_read_timeout      = lookup(custom_origin_config.value, "origin_read_timeout", null)
        }
      }

      dynamic "custom_header" {
        for_each = lookup(origin.value, "custom_header", [])

        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }

      dynamic "origin_shield" {
        for_each = length(keys(lookup(origin.value, "origin_shield", {}))) == 0 ? [] : [lookup(origin.value, "origin_shield", {})]

        content {
          enabled              = origin_shield.value.enabled
          origin_shield_region = origin_shield.value.origin_shield_region
        }
      }
    }
  }

  dynamic "origin_group" {
    for_each = var.origin_group

    content {
      origin_id = lookup(origin_group.value, "origin_id", origin_group.key)

      failover_criteria {
        status_codes = origin_group.value["failover_status_codes"]
      }

      member {
        origin_id = origin_group.value["primary_member_origin_id"]
      }

      member {
        origin_id = origin_group.value["secondary_member_origin_id"]
      }
    }
  }

  dynamic "default_cache_behavior" {
    for_each = [var.default_cache_behavior]
    iterator = i

    content {
      target_origin_id       = i.value["target_origin_id"]
      viewer_protocol_policy = i.value["viewer_protocol_policy"]
      allowed_methods           = lookup(i.value, "allowed_methods", ["GET", "HEAD", "OPTIONS"])
      cached_methods            = lookup(i.value, "cached_methods", ["GET", "HEAD"])
      compress                  = lookup(i.value, "compress", false)
      field_level_encryption_id = lookup(i.value, "field_level_encryption_id", null)
      smooth_streaming          = lookup(i.value, "smooth_streaming", null)
      trusted_signers           = lookup(i.value, "trusted_signers", null)
      trusted_key_groups        = lookup(i.value, "trusted_key_groups", null)
      cache_policy_id            = try(i.value.cache_policy_id, data.aws_cloudfront_cache_policy.this[i.value.cache_policy_name].id, null)
      origin_request_policy_id   = try(i.value.origin_request_policy_id, data.aws_cloudfront_origin_request_policy.this[i.value.origin_request_policy_name].id, null)
      response_headers_policy_id = try(i.value.response_headers_policy_id, data.aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy_name].id, null)
      realtime_log_config_arn = lookup(i.value, "realtime_log_config_arn", null)
      min_ttl     = lookup(i.value, "min_ttl", null)
      default_ttl = lookup(i.value, "default_ttl", null)
      max_ttl     = lookup(i.value, "max_ttl", null)
      
      #used for Lambda
      dynamic "lambda_function_association" {
        for_each = lookup(i.value, "lambda_associations", [])
        iterator = lambda

        content {
          event_type   = lambda.value.event_type
          lambda_arn   = lambda.value.lambda_arn
          include_body = lookup(lambda.value, "include_body", false)
        }
      }

      #used for CloudFront
      dynamic "function_association" {
        for_each = lookup(i.value, "function_associations", [])
        iterator = cloudfront

        content {
          event_type   = cloudfront.value.event_type
          function_arn = cloudfront.value.function_arn
        }
      }

      #Legacy cache settings
      dynamic "forwarded_values" {
        for_each = lookup(i.value, "cache_policy_id", null) == null && lookup(i.value, "use_forwarded_values", false) ? [true] : []
        #for_each = lookup(i.value, "use_forwarded_values", false) ? [true] : []

        content {
          query_string            = lookup(i.value, "query_string", null)
          query_string_cache_keys = lookup(i.value, "query_string_cache_keys", null)
          headers                 = lookup(i.value, "headers", null)

          cookies {
            forward           = lookup(i.value, "cookies_forward", null)
            whitelisted_names = lookup(i.value, "cookies_whitelisted_names", null)
          }
        }
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behavior
    iterator = i

    content {
      path_pattern           = i.value["path_pattern"]
      target_origin_id       = i.value["target_origin_id"]
      viewer_protocol_policy = i.value["viewer_protocol_policy"]
      allowed_methods           = lookup(i.value, "allowed_methods", ["GET", "HEAD", "OPTIONS"])
      cached_methods            = lookup(i.value, "cached_methods", ["GET", "HEAD"])
      compress                  = lookup(i.value, "compress", null)
      field_level_encryption_id = lookup(i.value, "field_level_encryption_id", null)
      smooth_streaming          = lookup(i.value, "smooth_streaming", null)
      trusted_signers           = lookup(i.value, "trusted_signers", null)
      trusted_key_groups        = lookup(i.value, "trusted_key_groups", null)
      cache_policy_id            = try(i.value.cache_policy_id, data.aws_cloudfront_cache_policy.this[i.value.cache_policy_name].id, null)
      origin_request_policy_id   = try(i.value.origin_request_policy_id, data.aws_cloudfront_origin_request_policy.this[i.value.origin_request_policy_name].id, null)
      response_headers_policy_id = try(i.value.response_headers_policy_id, data.aws_cloudfront_response_headers_policy.this[i.value.response_headers_policy_name].id, null)
      realtime_log_config_arn = lookup(i.value, "realtime_log_config_arn", null)

      min_ttl     = lookup(i.value, "min_ttl", null)
      default_ttl = lookup(i.value, "default_ttl", null)
      max_ttl     = lookup(i.value, "max_ttl", null)

      dynamic "forwarded_values" {
        for_each = lookup(i.value, "use_forwarded_values", true) ? [true] : []

        content {
          query_string            = lookup(i.value, "query_string", false)
          query_string_cache_keys = lookup(i.value, "query_string_cache_keys", [])
          headers                 = lookup(i.value, "headers", [])

          cookies {
            forward           = lookup(i.value, "cookies_forward", "none")
            whitelisted_names = lookup(i.value, "cookies_whitelisted_names", null)
          }
        }
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn            = lookup(var.viewer_certificate, "acm_certificate_arn", null)
    cloudfront_default_certificate = lookup(var.viewer_certificate, "cloudfront_default_certificate", null)
    iam_certificate_id             = lookup(var.viewer_certificate, "iam_certificate_id", null)

    minimum_protocol_version = lookup(var.viewer_certificate, "minimum_protocol_version", "TLSv1")
    ssl_support_method       = lookup(var.viewer_certificate, "ssl_support_method", null)
  }

  dynamic "custom_error_response" {
    for_each = length(flatten([var.custom_error_response])[0]) > 0 ? flatten([var.custom_error_response]) : []

    content {
      error_code = custom_error_response.value["error_code"]

      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", null)
    }
  }

  restrictions {
    dynamic "geo_restriction" {
      for_each = [var.geo_restriction]

      content {
        restriction_type = lookup(geo_restriction.value, "restriction_type", "none")
        locations        = lookup(geo_restriction.value, "locations", [])
      }
    }
  }
}

resource "aws_cloudfront_monitoring_subscription" "this" {
  count = var.create_distribution && var.create_monitoring_subscription ? 1 : 0

  distribution_id = aws_cloudfront_distribution.this[0].id

  monitoring_subscription {
    realtime_metrics_subscription_config {
      realtime_metrics_subscription_status = var.realtime_metrics_subscription_status
    }
  }
}

data "aws_cloudfront_cache_policy" "this" {
  for_each = toset([for v in concat([var.default_cache_behavior], var.ordered_cache_behavior) : v.cache_policy_name if can(v.cache_policy_name)])

  name = each.key
}

data "aws_cloudfront_origin_request_policy" "this" {
  for_each = toset([for v in concat([var.default_cache_behavior], var.ordered_cache_behavior) : v.origin_request_policy_name if can(v.origin_request_policy_name)])

  name = each.key
}

data "aws_cloudfront_response_headers_policy" "this" {
  for_each = toset([for v in concat([var.default_cache_behavior], var.ordered_cache_behavior) : v.response_headers_policy_name if can(v.response_headers_policy_name)])

  name = each.key
}