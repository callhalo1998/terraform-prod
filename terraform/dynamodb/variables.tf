variable "table_name" {
  type = string
}

variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}

variable "hash_key" {
  type = string
}

variable "hash_key_type" {
  type    = string
  default = "S"
}

variable "ttl_attribute_name" {
  type    = string
  default = "ttl"
}

variable "ttl_enabled" {
  type    = bool
  default = true
}

variable "pitr_enabled" {
  type    = bool
  default = false
}

variable "sse_enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type = map(string)
}

variable "pitr_recovery_period_in_days" {
  type    = number
  default = 7
}