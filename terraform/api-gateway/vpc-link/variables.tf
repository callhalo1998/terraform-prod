variable "vpc_links" {
  type = map(object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  }))
  default = null
}

variable "tags" {
  type = any
}