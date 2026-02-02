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
# ECR
# ------------------------------------------------------------------------------

resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  encryption_configuration {
    encryption_type = var.encryption_type
  }
  
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = {
    Name        = "${var.environment}-ecr"
    Environment = "${var.environment}"
    Terraform   = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = var.lifecycle_policy
}

resource "aws_ecr_registry_scanning_configuration" "configuration" {
  scan_type = var.scan_type

  dynamic "rule" {
    for_each = var.scan_rules
    content {
      scan_frequency = rule.value.scan_frequency

      repository_filter {
        filter      = rule.value.filter
        filter_type = "WILDCARD"
      }
    }
  }
}