variable "name" {
  description = "WebSocket API name"
  type        = string
}

variable "description" {
  description = "WebSocket API description"
  type        = string
  default     = null
}

variable "route_selection_expression" {
  description = "Expression to route messages"
  type        = string
  default     = "$request.body.action"
}

variable "stages" {
  description = "Stage map keyed by stage key (e.g., dev/prod)"
  type = map(object({
    name                   = string
    auto_deploy            = optional(bool, true)
    throttling_burst       = optional(number)
    throttling_rate        = optional(number)
    detailed_metrics       = optional(bool)
    access_log_enabled     = optional(bool, false)
    access_log_destination = optional(string)
    access_log_format      = optional(string, "$context.requestId $context.status")
  }))
}

variable "lambda_authorizers" {
  description = "Lambda (REQUEST) authorizers, keyed by reference name"
  type = map(object({
    authorizer_uri          = string
    identity_sources        = optional(list(string), ["route.request.header.Authorization"])
    ttl_seconds             = optional(number, 300)
    enable_simple_responses = optional(bool, true)
  }))
  default = null
}

variable "routes" {
  description = "Route definitions ($connect, $disconnect, $default, or custom)"
  type = list(object({
    route_key                 = string
    integration_type          = string                         # AWS_PROXY | HTTP | HTTP_PROXY | MOCK
    integration_uri           = string                         # Lambda ARN / URL / service ARN
    integration_method        = optional(string)               # for HTTP integrations
    timeout_ms                = optional(number)
    payload_format_version    = optional(string)               # 1.0 or 2.0
    passthrough_behavior      = optional(string)
    request_templates         = optional(map(string))
    template_selection_expression = optional(string)
    credentials_arn           = optional(string)

    auth = optional(object({
      type           = optional(string)  # NONE | CUSTOM | AWS_IAM (effective on $connect)
      authorizer_ref = optional(string)  # key in lambda_authorizers
    }))
  }))
}

variable "custom_domain" {
  description = "Custom domain for WebSocket API (optional)"
  type = object({
    enabled         = bool
    domain_name     = string
    certificate_arn = string
    endpoint_type   = optional(string, "REGIONAL")
    security_policy = optional(string, "TLS_1_2")
    mappings = optional(list(object({
      stage     = string
      base_path = optional(string)
    })), [])
  })
  default = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "vpc_link_id" {
  description = "Shared API Gateway VPC Link ID (for private integrations)"
  type        = string
  default     = null
}