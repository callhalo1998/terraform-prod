output "ssm_parameter_names" {
  description = "List of created SSM parameter names"
  value       = [for p in aws_ssm_parameter.this : p.name]
}

output "ssm_parameter_arns" {
  description = "List of created SSM parameter ARNs"
  value       = [for p in aws_ssm_parameter.this : p.arn]
}