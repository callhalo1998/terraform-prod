variable "environment" {
  description = "The deployment environment (e.g. dev, prod)"
  type        = string
}

variable "ssm_params" {
  description = "Map of SSM parameter names to their types and values"
  type = map(object({
    type  = string
    value = string
  }))
}

variable "tags" {
  type    = any
  default = {}
}