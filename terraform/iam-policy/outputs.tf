output "policy_name" {
  value       = aws_iam_policy.this.name
  description = "Use this with SSO PermissionSet customer_policies."
}

output "policy_path" {
  value       = aws_iam_policy.this.path
  description = "Path for SSO attachment if not '/'."
}

output "policy_arn" {
  value       = aws_iam_policy.this.arn
  description = "Full ARN (useful for diagnostics/other attachments)."
}

output "policy_name_map" {
  value       = { (aws_iam_policy.this.name) = aws_iam_policy.this.name }
}

output "policy_path_map" {
  value       = { (aws_iam_policy.this.name) = aws_iam_policy.this.path }
}