variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "log_groups" {
  description = "Map of CloudWatch log groups to create"
  type = map(object({
    name              = string
    retention_in_days = number
    kms_key_id        = optional(string)
    tags              = optional(map(string))
  }))
}
