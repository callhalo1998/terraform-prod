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
# Secret Manager
# ------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name        = each.key
  description = lookup(each.value, "description", null)

  tags = merge(
    {
      Name        = "${var.environment}-secret"
      Environment = var.environment
      Terraform   = "true"
    },
    lookup(each.value, "tags", {})
  )
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each  = var.secrets
  secret_id = aws_secretsmanager_secret.this[each.key].id
  secret_string = (
    can(tomap(each.value.secrets)) || can(tolist(each.value.secrets))
      ? jsonencode(each.value.secrets)
      : tostring(each.value.secrets)
  )
}