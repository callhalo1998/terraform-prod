variable "name" {
  description = "Name of the API Gateway HTTP API"
  type        = string
}

variable "description" {
  description = "Description of the API Gateway HTTP API"
  type        = string
  default     = ""
}

variable "cors" {
  description = "CORS configuration for the API (optional)"
  type = object({
    enabled           = optional(bool, false)
    allow_credentials = optional(bool)
    allow_headers     = optional(list(string))
    allow_methods     = optional(list(string))
    allow_origins     = optional(list(string))
    expose_headers    = optional(list(string))
    max_age           = optional(number)
  })
  default = null
}

variable "stages" {
  description = "Map of API Gateway stages"
  type = map(object({
    name                   = string
    description            = optional(string)
    auto_deploy            = optional(bool, true)

    throttling_burst       = optional(number)
    throttling_rate        = optional(number)
    detailed_metrics       = optional(bool)

    access_log_enabled     = optional(bool, false)
    access_log_destination = optional(string)
    access_log_format      = optional(string)
  }))
  default = {}
}

variable "jwt_authorizers" {
  description = "Optional map of JWT authorizers"
  type = map(object({
    issuer    = string
    audiences = optional(list(string), [])
  }))
  default = null
}

variable "lambda_authorizers" {
  description = "Optional map of Lambda authorizers"
  type = map(object({
    authorizer_uri            = string # Lambda invoke URI
    enable_simple_responses   = optional(bool, true)
    ttl_seconds               = optional(number, 300)
    identity_sources          = optional(list(string), ["$request.header.Authorization"])
  }))
  default = null
}

variable "vpc_links" {
  type = map(object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
    tags               = optional(map(string), {})
  }))
  default = null
}

variable "tags" {
  description = "Global tags to apply"
  type        = map(string)
  default     = {}
}

variable "routes" {
  description = "List of API Gateway routes and integrations"
  type = list(object({
    route_key              = string                          # e.g., "ANY /", "POST /webhook"
    integration_type       = string                          # "AWS_PROXY" | "HTTP_PROXY"
    integration_method     = optional(string)                # e.g., "GET", "POST", "ANY" (HTTP_PROXY only)
    integration_uri        = string                          # Lambda ARN, ALB/NLB listener ARN, Cloud Map ARN, or HTTP URL
    connection_type        = optional(string, "INTERNET")    # "INTERNET" | "VPC_LINK"
    connection_id          = optional(string)                # VPC Link ID (if VPC_LINK)
    timeout_ms             = optional(number)                # e.g., 5000
    payload_format_version = optional(string)                # "2.0" for Lambda proxy
    request_parameters     = optional(map(string))           # Optional request params
  }))
  default = []
}

variable "custom_domain" {
  description = "Custom domain config for HTTP API (no Route53)"
  type = object({
    enabled         = optional(bool, false)
    domain_name     = string
    certificate_arn = string                      # Regional ACM in same region
    endpoint_type   = optional(string, "REGIONAL")
    security_policy = optional(string, "TLS_1_2")
    mappings = optional(list(object({
      stage     = string                          # key in var.stages
      base_path = optional(string)                # null or ""
    })), [])
  })
  default = null
}

variable "waf" {
  description = "Optional WAF configuration to associate with API Gateway stages"
  type = object({
    enabled     = optional(bool, false)
    web_acl_arn = string
  })
  default = null
}

variable "vpc_link_id" {
  description = "Existing API Gateway VPC Link ID to use for VPC_LINK integrations (shared by HTTP & WS)."
  type        = string
  default     = null
}