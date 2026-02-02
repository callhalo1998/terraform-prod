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
# CloudWatch log group
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  for_each = var.log_groups

  name              = each.value.name
  retention_in_days = each.value.retention_in_days
  kms_key_id        = lookup(each.value, "kms_key_id", null)

  tags = merge(
    {
      Name        = each.value.name
      Environment = var.environment
      Terraform   = true
    },
    lookup(each.value, "tags", {})
  )
}
