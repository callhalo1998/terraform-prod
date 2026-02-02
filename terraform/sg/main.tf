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

# ------------------------------------------------------------------------------
# SG
# ------------------------------------------------------------------------------

resource "aws_security_group" "this" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = var.vpc_id

# ------------------------------------------------------------------------------
# Ingress / inbound
# ------------------------------------------------------------------------------

  dynamic "ingress" {
    for_each = lookup(each.value, "ingress", [])
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", [])
      security_groups  = lookup(ingress.value, "security_groups", [])
      prefix_list_ids  = lookup(ingress.value, "prefix_list_ids", [])
      self             = try(ingress.value.self, null)
      description      = lookup(ingress.value, "description", null)
    }
  }

# ------------------------------------------------------------------------------
# Egress / outbound
# ------------------------------------------------------------------------------

  dynamic "egress" {
    for_each = lookup(each.value, "egress", [])
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = lookup(egress.value, "cidr_blocks", [])
      security_groups  = lookup(egress.value, "security_groups", [])
      prefix_list_ids  = lookup(egress.value, "prefix_list_ids", [])
    }
  }

  tags = merge(
    {
      Name        = "${var.environment}-sg"
      Terraform   = "true"
    },
    var.tags
  )
}
