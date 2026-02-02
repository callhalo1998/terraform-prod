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
# VPC LINKS
# ------------------------------------------------------------------------------

resource "aws_apigatewayv2_vpc_link" "this" {
  for_each = var.vpc_links == null ? {} : var.vpc_links
  name               = each.key
  security_group_ids = try(each.value.security_group_ids, null)
  subnet_ids         = each.value.subnet_ids
  tags               = merge(var.tags, try(each.value.tags, {}))
}