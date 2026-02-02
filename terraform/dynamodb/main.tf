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
# DynamoDB Table
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = var.billing_mode

  hash_key = var.hash_key

  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  ttl {
    attribute_name = var.ttl_attribute_name
    enabled        = var.ttl_enabled
  }

  point_in_time_recovery {
    enabled                 = var.pitr_enabled
    recovery_period_in_days = var.pitr_recovery_period_in_days
  }

  server_side_encryption {
    enabled = var.sse_enabled
  }

  tags = var.tags
}
