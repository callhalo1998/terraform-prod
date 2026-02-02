
variable "environment" {
  type = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = null
}

variable "create_vpc" {
  description = "Whether to create the VPC"
  type        = bool
  default     = false
}

variable "create_igw" {
  type    = bool
  default = false
}

variable "create_nat_gateway" {
  type        = bool
  default     = false
}

variable "nat_gateways" {
  type = map(object({
    subnet_id     = string
    allocation_id = optional(string)
  }))
  default = {}
}

variable "create_nacl" {
  type    = bool
  default = false
}

variable "vpc_id" {
  type = string
  default = null
}

variable "igw_id" {
  type = string
  default = null
}

variable "nat_gateway_id" {
  type = string
  default = null
}

variable "public_subnets" {
  type    = map(any)
  default = {}
}

variable "private_subnets" {
  type    = any
  default = {}
}

variable "route_tables" {
  type    = map(any)
  default = {}
}

variable "eips_to_create" {
  description = "List of EIPs to create. Each item is a name tag."
  type        = list(string)
  default     = []
}

variable "nacls" {
  type = map(object({
    subnet_ids = map(string)

    ingress = list(object({
      rule_number = number
      protocol    = string
      rule_action = string
      cidr_block  = string
      from_port   = number
      to_port     = number
    }))

    egress = list(object({
      rule_number = number
      protocol    = string
      rule_action = string
      cidr_block  = string
      from_port   = number
      to_port     = number
    }))
  }))
  default     = {}
}

variable "tags" {
  type    = any
  default = {}
}