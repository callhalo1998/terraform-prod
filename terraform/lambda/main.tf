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
# Optional Security group for outbound traffic  
# ------------------------------------------------------------------------------

resource "aws_security_group" "lambda_sg" {
  count       = var.create_outbound_traffic ? 1 : 0
  name        = "${var.function_name}-sg"
  description = "Security group for Lambda ${var.function_name}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.function_name}-sg"
    Environment = "${var.environment}"
    Terraform   = true
  }
}

# ------------------------------------------------------------------------------
# Lambda
# ------------------------------------------------------------------------------

## locals {
#   lambda_security_group_ids = (
#     var.create_outbound_traffic
#       ? aws_security_group.lambda_sg[*].id
#       : var.vpc_config.security_group_ids
#   )
# }

locals {
  lambda_security_group_ids = var.create_outbound_traffic ? aws_security_group.lambda_sg[*].id : try(var.vpc_config.security_group_ids, [])
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  handler          = var.handler
  runtime          = var.runtime
  # filename         = data.archive_file.lambda_zip.output_path
  # source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  filename         = "${path.module}/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")

  role          = var.role_arn
  timeout       = var.timeout
  memory_size   = var.memory_size

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [1] : []
    content {
        subnet_ids         = var.vpc_config.subnet_ids
        security_group_ids = local.lambda_security_group_ids
    }
  }

  environment {
    variables = var.environment_variables
  }

  tags = {
    Name        = "${var.environment}-${var.function_name}"
    Environment = "${var.environment}"
    Terraform   = true
  }
}

# ------------------------------------------------------------------------------
# Allow to trigger Lambda (e.g. API Gateway)
# ------------------------------------------------------------------------------

resource "aws_lambda_permission" "this" {
  count         = var.create_lambda_permission ? 1 : 0
  statement_id  = "AllowExecutionFromTrigger"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = var.lambda_permission.principal
  source_arn    = var.lambda_permission.source_arn
}

# ------------------------------------------------------------------------------
# Enable Function URL (Public Lambda Endpoint) + Permission for Funtion URL
# ------------------------------------------------------------------------------

resource "aws_lambda_function_url" "this" {
  count              = var.enable_function_url ? 1 : 0
  function_name      = aws_lambda_function.this.function_name
  authorization_type = var.function_url_auth_type
}