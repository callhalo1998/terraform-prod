variable "function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "The function entrypoint (e.g., trigger.lambda_handler)"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.12, nodejs18.x)"
  type        = string
}

variable "source_path" {
  description = "Path to Lambda source code directory (e.g., lambda_src)"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 128
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "role_arn" {
  description = "IAM Role ARN to attach to the Lambda. If null, a placeholder role will be created"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to associate with Lambda (required if using VPC config)"
  type        = string
  default     = null
}

variable "vpc_config" {
  description = <<EOF
Optional VPC config:
{
  subnet_ids         = list(string)
  security_group_ids = list(string)  # Required only if create_outbound_traffic = false
}
EOF
  type    = any
  default = null
}

variable "create_outbound_traffic" {
  description = "Set to true to create a default security group allowing all outbound traffic"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(any)
  default     = {}
}

variable "create_lambda_permission" {
  type    = bool
  default = false
}

variable "lambda_permission" {
  type = object({
    principal  = string
    source_arn = optional(string)
  })
  default = null
}

variable "enable_function_url" {
  description = "Whether to enable Lambda Function URL"
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "Auth type for Lambda Function URL. Valid values: NONE or AWS_IAM"
  type        = string
  default     = "NONE"
  validation {
    condition     = contains(["NONE", "AWS_IAM"], var.function_url_auth_type)
    error_message = "function_url_auth_type must be either 'NONE' or 'AWS_IAM'."
  }
}
