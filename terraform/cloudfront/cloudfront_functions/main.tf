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
# CLOUDFRONT FUNCTION
# ------------------------------------------------------------------------------

resource "aws_cloudfront_function" "this" {
  name    = var.function_name
  runtime = var.runtime
  comment = var.comment
  publish = var.publish
  code    = file(var.code_file)
}
