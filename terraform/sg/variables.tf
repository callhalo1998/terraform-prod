variable "vpc_id" {
  description = "The ID of the VPC where the security groups will be created"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "security_groups" {
  description = "Map of security groups with their ingress/egress rules"
  type = any
}

variable "tags" {
  type    = any
  default = {}
}