output "cloudfront_function_arn" {
  description = "ARN of the CloudFront function"
  value       = aws_cloudfront_function.this.arn
}

output "function_status" {
  description = "Status of the CloudFront function (UNPUBLISHED, UNASSOCIATED, or ASSOCIATED)"
  value       = aws_cloudfront_function.this.status
}