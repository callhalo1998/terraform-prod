variable "cache_policy_name" {
  description = "The name of the CloudFront cache policy"
  type        = string
  default     = "example-policy"
}

variable "cache_policy_comment" {
  description = "A comment for the cache policy"
  type        = string
  default     = ""
}

variable "cache_policy_default_ttl" {
  description = "The default TTL for the cache policy"
  type        = number
  default     = 86400
}

variable "cache_policy_max_ttl" {
  description = "The maximum TTL for the cache policy"
  type        = number
  default     = 31536000
}

variable "cache_policy_min_ttl" {
  description = "The minimum TTL for the cache policy"
  type        = number
  default     = 1
}

variable "headers_behavior" {
  type    = string
  default = "none"
}

variable "headers_items" {
  type    = list(string)
  default = []
}

variable "query_string_behavior" {
  type    = string
  default = "none"
}

variable "query_strings_items" {
  type    = list(string)
  default = []
}

variable "cookie_behavior" {
  type    = string
  default = "none"
}

variable "cookies_items" {
  type    = list(string)
  default = []
}

variable "enable_accept_encoding_brotli" {
  type    = bool
  default = true
}

variable "enable_accept_encoding_gzip" {
  type    = bool
  default = true
}