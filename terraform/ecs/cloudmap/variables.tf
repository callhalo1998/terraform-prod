variable "namespaces" {
  description = "List of Cloud Map namespaces"
  type = list(object({
    name   = string
    vpc_id = string
  }))
}

variable "services" {
  description = "List of Cloud Map services"
  type = list(object({
    name           = string
    namespace_name = string
    dns_record_type = string
    dns_record_ttl  = number
    routing_policy  = string
  }))
}
