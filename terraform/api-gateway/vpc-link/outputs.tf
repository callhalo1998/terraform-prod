output "vpc_link_ids" {
  value       = { for k, r in aws_apigatewayv2_vpc_link.this : k => r.id }
}

output "vpc_link_arns" {
  value       = { for k, r in aws_apigatewayv2_vpc_link.this : k => r.arn }
}

output "vpc_link_names" {
  value       = { for k, r in aws_apigatewayv2_vpc_link.this : k => r.name }
}