variable "environment" {
  type = string
}

variable "service_name" {
  type    = string
  default = ""
}

variable "container_image" {
  type    = string
  default = ""
}

variable "container_port" {
  type    = number
  default = null
}

variable "enable_blue_green" {
  type    = bool
  default = false
}

variable "container_env" {
  description = "Map of environment variables to inject into the container"
  type        = any
  default     = null
}

variable "container_secrets" {
  type = map(object({
    arn = string
    key = optional(string)
  }))
  default = {}
}

variable "log_group_name" {
  type    = string
  default = ""
}

variable "region" {
  type    = string
  default = ""
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}

variable "execution_role_arn" {
  type    = string
  default = ""
}

variable "task_role_arn" {
  type    = string
  default = ""
}

variable "requires_compatibilities" {
  type    = list(string)
  default = []
}

variable "cluster_name" {
  type = string
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "security_group_id" {
  type    = string
  default = ""
}

variable "target_group_arn" {
  description = "ARN of the target group for the load balancer"
  type        = string
  default     = null
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "assign_public_ip" {
  type    = bool
  default = false
}

variable "use_launch_type" {
  description = "Whether to use launch_type in ECS service"
  type        = bool
  default     = false
}

variable "launch_type" {
  type    = string
  default = ""
}

variable "use_capacity_provider_strategy" {
  description = "Whether to use capacity_provider_strategy"
  type        = bool
  default     = false
}

variable "capacity_provider_strategy" {
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number)
  }))
  default = []
}

variable "minimum_healthy_percent" {
  type    = number
  default = 50
}

variable "maximum_percent" {
  type    = number
  default = 200
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

variable "cloudmap_service_arn" {
  description = "ARN of the Cloud Map service for ECS service discovery"
  type        = string
  default     = null
}

variable "load_balancers" {
  description = "List of target groups to attach (one per port)."
  type = list(object({
    target_group_arn = string
    container_port   = number
  }))
  default = []
}

variable "autoscaling" {
  type = object({
    min_capacity          = number
    max_capacity          = number
    cpu_target            = optional(number, 70)
    memory_target         = optional(number, 75)
    scale_in_cooldown     = optional(number, 60)
    scale_out_cooldown    = optional(number, 60)
    enable_cpu_policy     = optional(bool, true)
    enable_memory_policy  = optional(bool, true)
  })
  default = null
}

variable "resource_id" {
  type    = string
  default = null
}

variable "container_ports" {
  description = "List of container ports to expose in the task definition"
  type        = list(number)
  default     = null
}

variable "service_account" {
  description = "Service Connect configuration block"
  type = object({
    cloudmap_namespace_arn = string
    port_name              = string
  })
  default = null
}

variable "network_mode" {
  description = "The Docker networking mode to use for the containers in the task"
  type        = string
}