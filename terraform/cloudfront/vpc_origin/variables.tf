variable "vpc_origin_name" {
  type        = string
  description = "Name of the CloudFront VPC origin"
}

variable "arn" {
  type        = string
}

variable "http_port" {
  type        = number
  default     = 80
}

variable "https_port" {
  type        = number
  default     = 443
}

variable "origin_protocol_policy" {
  type        = string
  default     = "https-only"
  description = "http-only, https-only, or match-viewer"
}

variable "origin_ssl_protocols" {
  type        = list(string)
  default     = ["TLSv1.2"]
  description = "List of SSL protocols (only used if HTTPS is enabled)"
}
