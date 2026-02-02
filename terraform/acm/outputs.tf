output "certificate_arn" {
  description = "The ARN of the ACM certificate"
  value       = aws_acm_certificate.this.arn
}

output "certificate_domain_name" {
  description = "The domain name for the ACM certificate"
  value       = aws_acm_certificate.this.domain_name
}

output "certificate_status" {
  description = "Status of the ACM certificate"
  value       = aws_acm_certificate.this.status
}
