variable "function_name" {
  description = "Name of the CloudFront function"
  type        = string
}

variable "runtime" {
  description = "Runtime for the CloudFront function"
  type        = string
  default     = "cloudfront-js-2.0"
}

variable "comment" {
  description = "Comment for the CloudFront function"
  type        = string
  default     = null
}

variable "publish" {
  description = "Whether to publish the CloudFront function"
  type        = bool
  default     = false
}

variable "code_file" {
  description = "Path to the CloudFront function code file"
  type        = string
}
