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
# VPC Origin
# ------------------------------------------------------------------------------

resource "aws_cloudfront_vpc_origin" "this" {
  vpc_origin_endpoint_config {
    name                   = var.vpc_origin_name
    arn                    = var.arn
    http_port              = var.http_port
    https_port             = var.https_port
    origin_protocol_policy = var.origin_protocol_policy

    origin_ssl_protocols {
      items    = var.origin_ssl_protocols
      quantity = length(var.origin_ssl_protocols)
    }
  }
}
