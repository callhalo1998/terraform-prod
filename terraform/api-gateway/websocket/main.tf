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
# WEBSOCKET API
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_api" "this" {
  name                       = var.name
  description                = var.description
  protocol_type              = "WEBSOCKET"
  route_selection_expression = var.route_selection_expression
  tags                       = var.tags
}

# ------------------------------------------------------------------------------
# STAGES
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_stage" "stage" {
  for_each    = var.stages
  api_id      = aws_apigatewayv2_api.this.id
  name        = each.value.name
  auto_deploy = try(each.value.auto_deploy, true)

  default_route_settings {
    throttling_burst_limit     = try(each.value.throttling_burst, null)
    throttling_rate_limit      = try(each.value.throttling_rate, null)
    detailed_metrics_enabled   = try(each.value.detailed_metrics, null)
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
# AUTHORIZERS (only Lambda/REQUEST)
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_authorizer" "lambda" {
  for_each        = var.lambda_authorizers == null ? {} : var.lambda_authorizers
  api_id          = aws_apigatewayv2_api.this.id
  name            = each.key
  authorizer_type = "REQUEST"
  authorizer_uri  = each.value.authorizer_uri
  identity_sources = try(each.value.identity_sources, ["route.request.header.Authorization"])
  authorizer_result_ttl_in_seconds = try(each.value.ttl_seconds, 300)
  enable_simple_responses          = try(each.value.enable_simple_responses, true)
}

# ------------------------------------------------------------------------------
# INTEGRATIONS
# ------------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "this" {
  for_each = { for r in var.routes : r.route_key => r }

  api_id                    = aws_apigatewayv2_api.this.id
  integration_type          = each.value.integration_type          # "AWS_PROXY" | "HTTP" | "HTTP_PROXY" | "MOCK"
  integration_uri           = each.value.integration_uri           # Lambda ARN / HTTP URL / AWS service ARN
  integration_method        = try(each.value.integration_method, null) # required for HTTP integrations
  timeout_milliseconds      = try(each.value.timeout_ms, null)
  payload_format_version    = try(each.value.payload_format_version, "1.0") # WebSocket supports 1.0/2.0
  passthrough_behavior      = try(each.value.passthrough_behavior, null)    # WHEN_NO_MATCH|WHEN_NO_TEMPLATES|NEVER (WS)
  request_templates         = try(each.value.request_templates, null)
  template_selection_expression = try(each.value.template_selection_expression, null)
  credentials_arn           = try(each.value.credentials_arn, null) # for AWS service integrations
  connection_type           = try(each.value.connection_type, "INTERNET")
  connection_id             = (try(each.value.connection_type, "INTERNET") == "VPC_LINK" ? var.vpc_link_id : null)
}

# ------------------------------------------------------------------------------
# ROUTES ($connect, $disconnect, $default, + custom)
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_route" "this" {
  for_each = { for r in var.routes : r.route_key => r }

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.this[each.key].id}"

  authorization_type = (
    each.key == "$connect"
    ? try(upper(each.value.auth.type), "NONE") # "NONE" | "AWS_IAM" | "CUSTOM"
    : "NONE"
  )

  authorizer_id = (
    each.key == "$connect" && try(upper(each.value.auth.type), "NONE") == "CUSTOM"
      ? try(aws_apigatewayv2_authorizer.lambda[each.value.auth.authorizer_ref].id, null)
      : null
  )
}

# ------------------------------------------------------------------------------
# CUSTOM DOMAINS
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_domain_name" "this" {
  count = var.custom_domain != null && try(var.custom_domain.enabled, false) ? 1 : 0

  domain_name = var.custom_domain.domain_name
  domain_name_configuration {
    certificate_arn = var.custom_domain.certificate_arn
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

  api_id          = aws_apigatewayv2_api.this.id
  domain_name     = aws_apigatewayv2_domain_name.this[0].id
  stage           = aws_apigatewayv2_stage.stage[each.value.stage].name
  api_mapping_key = try(each.value.base_path, null)
}