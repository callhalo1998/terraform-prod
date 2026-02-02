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
# HTTP API + CORS
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  description   = var.description
  protocol_type = "HTTP"

  dynamic "cors_configuration" {
    for_each = var.cors != null && try(var.cors.enabled, false) ? [1] : []
    content {
      allow_credentials = try(var.cors.allow_credentials, null)
      allow_headers     = try(var.cors.allow_headers, null)
      allow_methods     = try(var.cors.allow_methods, null)
      allow_origins     = try(var.cors.allow_origins, null)
      expose_headers    = try(var.cors.expose_headers, null)
      max_age           = try(var.cors.max_age, null)
    }
  }

  tags = var.tags
}

# ------------------------------------------------------------------------------  
# STAGES
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_stage" "stage" {
  for_each = var.stages
  api_id   = aws_apigatewayv2_api.this.id
  name     = each.value.name
  auto_deploy = try(each.value.auto_deploy, true)
  
  default_route_settings {
    throttling_burst_limit = try(each.value.throttling_burst, null)
    throttling_rate_limit  = try(each.value.throttling_rate, null)
    detailed_metrics_enabled = try(each.value.detailed_metrics, null)
  }

  dynamic "access_log_settings" {
    for_each = try(each.value.access_log_enabled, false) && try(each.value.access_log_destination, "") != "" ? [1] : []
    content {
      destination_arn = each.value.access_log_destination
      format          = try(each.value.access_log_format, "$context.requestId $context.status")
    }
  }

  tags = var.tags
}

# ------------------------------------------------------------------------------  
# INTEGRATION
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_integration" "this" {
  for_each = {
    for r in var.routes : r.route_key => r
  }

  api_id = aws_apigatewayv2_api.this.id

  integration_type          = each.value.integration_type
  integration_method        = try(each.value.integration_method, null)
  integration_uri           = each.value.integration_uri 
  connection_type           = try(each.value.connection_type, "INTERNET")
  connection_id   = (
    try(each.value.connection_type, "INTERNET") == "VPC_LINK"
    ? var.vpc_link_id
    : null
  )
  timeout_milliseconds      = try(each.value.timeout_ms, null)
  payload_format_version    = try(each.value.payload_format_version, null)
  request_parameters        = try(each.value.request_parameters, null)
}

# ------------------------------------------------------------------------------  
# ROUTES
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_route" "this" {
  for_each = { for r in var.routes : r.route_key => r }

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.this[each.key].id}"

  authorization_type   = try(upper(each.value.auth.type), "NONE")
  authorizer_id        = null
  authorization_scopes = null
}

# ------------------------------------------------------------------------------  
# CUSTOM DOMAINS
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_domain_name" "this" {
  count = var.custom_domain != null && try(var.custom_domain.enabled, false) ? 1 : 0

  domain_name = var.custom_domain.domain_name
  domain_name_configuration {
    certificate_arn = var.custom_domain.certificate_arn  # must be in same region
    endpoint_type   = try(var.custom_domain.endpoint_type, "REGIONAL")
    security_policy = try(var.custom_domain.security_policy, "TLS_1_2")
  }
  tags = var.tags
}

resource "aws_apigatewayv2_api_mapping" "this" {
  for_each = (
    length(aws_apigatewayv2_domain_name.this) == 1
    ? { for i, m in try(var.custom_domain.mappings, []) : i => m }
    : {}
  )

  api_id       = aws_apigatewayv2_api.this.id
  domain_name  = aws_apigatewayv2_domain_name.this[0].id  # id === domain_name
  stage        = aws_apigatewayv2_stage.stage[each.value.stage].name
  api_mapping_key = try(each.value.base_path, null)
}

# ------------------------------------------------------------------------------  
# ATTACH WAF
# ------------------------------------------------------------------------------

resource "aws_wafv2_web_acl_association" "this" {
  for_each = var.waf != null && try(var.waf.enabled, false) ? var.stages : {}
  resource_arn = aws_apigatewayv2_stage.stage[each.key].arn
  web_acl_arn  = var.waf.web_acl_arn
}