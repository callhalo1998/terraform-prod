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
# IAM Policy
# ------------------------------------------------------------------------------

resource "aws_iam_policy" "this" {
  name        = var.policy_name
  path        = var.policy_path
  description = var.description
  policy      = var.policy_document_json
  tags        = var.tags
}