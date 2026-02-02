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
# SSM Parameter store
# ------------------------------------------------------------------------------

resource "aws_ssm_parameter" "this" {
  for_each = var.ssm_params

  name  = each.key
  type  = each.value.type
  value = each.value.value

  tags = merge(
    {
      Name        = "${var.environment}-ssm"
      Terraform   = "true"
    },
    var.tags
  )
}
