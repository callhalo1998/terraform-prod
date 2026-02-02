variable "sso_home_region" {
  type = string
}

variable "groups" {
  type = list(object({
    display_name = string
    description  = optional(string)
  }))
  default = []
}

variable "users" {
  type = list(object({
    user_name    = string
    display_name = optional(string)
    given_name   = string
    family_name  = string
    email        = string
    groups       = list(string)
  }))
  default = []
}

variable "permission_sets" {
  type = map(object({
    description       = optional(string)
    session_duration  = optional(string)
    tags              = optional(map(string))
    aws_managed_policy = optional(list(string))
    customer_policies  = optional(list(string))
  }))
  default = {}
}

variable "account_assignments" {
  type = map(object({
    principal_type  = string
    principal_name  = string
    permission_sets = list(string)
    account_ids     = list(string)
  }))
  default = {}
}
