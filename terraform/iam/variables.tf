variable "create_role" {
  description = "Whether to create the IAM role"
  type        = bool
  default     = true
}

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "assume_role_policy" {
  description = "Assume role policy in JSON"
  type        = string
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = null
}

variable "role_path" {
  description = "Path for the IAM role"
  type        = string
  default     = "/"
}

variable "create_inline_policy" {
  description = "Whether to create inline policies"
  type        = bool
  default     = false
}

variable "inline_policies" {
  description = "Map of inline policy name => JSON content"
  type        = map(string)
  default     = {}
}

variable "attached_policies" {
  description = "Map of name => managed policy ARN to attach"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
}

variable "create_instance_profile" {
  description = "Whether to create an IAM Instance Profile for the role"
  type        = bool
  default     = false
}

variable "instance_profile_name" {
  description = "Optional explicit name for the Instance Profile; defaults to role_name"
  type        = string
  default     = null
}

variable "instance_profile_path" {
  description = "Optional path for the Instance Profile"
  type        = string
  default     = null
}