variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "use_capacity_provider_strategy" {
  description = "Whether to create ECS Capacity Provider for EC2 launch type"
  type        = bool
  default     = false
}

variable "capacity_provider_name" {
  type        = string
  description = "Name of the ECS Capacity Provider"
  default     = ""
}

variable "asg_arn" {
  type        = string
  description = "ARN of the Auto Scaling Group"
  default     = ""
}

variable "managed_termination_protection" {
  type        = string
  description = "ENABLE or DISABLED"
  default     = "DISABLED"
}

variable "maximum_scaling_step_size" {
  type        = number
  description = "Max scaling step size"
  default     = 1
}

variable "minimum_scaling_step_size" {
  type        = number
  description = "Min scaling step size"
  default     = 1
}

variable "scaling_status" {
  type        = string
  description = "Managed scaling status (ENABLED or DISABLED)"
  default     = "DISABLED"
}

variable "target_capacity" {
  type        = number
  description = "Target capacity for ECS-managed scaling"
  default     = 100
}

variable "default_strategy_weight" {
  type        = number
  description = "Default weight for capacity provider in cluster"
  default     = 0
}

variable "enable_fargate_capacity_providers" { 
  type = bool   
  default = false
}

variable "default_capacity_provider_strategies" {
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))
  default = []
}