variable "name" {
  description = "Load balancer name"
  type        = string
}

variable "internal" {
  description = "true = internal, false = internet-facing"
  type        = bool
  default     = false
}

variable "load_balancer_type" {
  description = "application (ALB) or network (NLB)"
  type        = string
  default     = "application"

  validation {
    condition     = contains(["application", "network"], var.load_balancer_type)
    error_message = "load_balancer_type must be one of: application, network."
  }
}

variable "subnet_ids" {
  description = "Subnets for the LB"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups (only for ALB)"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Tag value for Environment"
  type        = string
  default     = null
}

variable "tags" {
  description = "Extra tags to merge"
  type        = map(string)
  default     = {}
}

# ------------------------------
# Target Groups
# ------------------------------
variable "vpc_id" {
  description = "VPC ID for target groups"
  type        = string
  default     = null
}

variable "target_type" {
  description = "Target type for TGs: instance | ip | lambda"
  type        = string
  default     = "instance"

  validation {
    condition     = contains(["instance", "ip", "lambda"], var.target_type)
    error_message = "target_type must be one of: instance, ip, lambda."
  }
}

variable "target_groups" {
  description = "List of target groups to create"
  type = list(object({
    name                              = string
    port                              = number
    protocol                          = string               # HTTP | HTTPS | TCP | UDP | TLS
    target_type                       = optional(string)     # Override default target_type per TG
    health_check_enabled              = bool
    health_check_protocol             = string               # HTTP | TCP
    health_check_path                 = optional(string)     # required nếu protocol == HTTP
    health_check_interval             = optional(number, 120)
    health_check_timeout              = optional(number, 60)
    health_check_healthy_threshold    = optional(number, 2)
    health_check_unhealthy_threshold  = optional(number, 2)
    health_check_matcher              = optional(string, "200")  # chỉ dùng khi HTTP
  }))
  default = []
}

# ------------------------------
# Listeners (HTTP/HTTPS/TCP/...)
# ------------------------------
variable "listeners" {
  type = list(object({
    name                      = string
    port                      = number
    protocol                  = string
    default_target_group_name = optional(string)
    target_groups = optional(list(object({
      name   = string
      weight = optional(number)
    })), [])
    stickiness = optional(object({
      enabled  = bool
      duration = number
    }))
    certificate_arn = optional(string)
    ssl_policy      = optional(string)
  }))
  default = []
}

# ------------------------------
# Listener Rules (path/host-based...)
# ------------------------------
variable "listener_rules" {
  description = "List of listener rules"
  type = list(object({
    listener_name = string
    priority      = number

    # NOTE: main.tf hiện dùng dạng field/values; type mặc định path_pattern
    conditions = list(object({
      type   = optional(string, "path_pattern") # e.g. path_pattern | host_header | http_request_method | source_ip | http_header | query_string
      values = list(string)
    }))

    actions = list(object({
      type              = string                 # e.g. "forward"
      target_group_name = string
    }))
  }))
  default = []
}

variable "deregistration_delay" {
  description = "The amount of time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused."
  type        = number
  default     = 60
}