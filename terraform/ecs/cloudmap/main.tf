terraform {
  backend "s3" {}
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

# --------------------------------------------------
# Namespaces
# --------------------------------------------------

resource "aws_service_discovery_private_dns_namespace" "this" {
  for_each = { for ns in var.namespaces : ns.name => ns }

  name = each.value.name
  vpc  = each.value.vpc_id
}

# --------------------------------------------------
# Services
# --------------------------------------------------

resource "aws_service_discovery_service" "this" {
  for_each = {
    for svc in var.services :
    "${svc.namespace_name}-${svc.name}" => svc
  }

  name = each.value.name

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this[each.value.namespace_name].id

    dns_records {
      type = each.value.dns_record_type
      ttl  = each.value.dns_record_ttl
    }

    routing_policy = each.value.routing_policy
  }
}