output "role_name" {
  description = "IAM Role name"
  value       = aws_iam_role.this[0].name
}

output "role_arn" {
  description = "IAM Role ARN"
  value       = aws_iam_role.this[0].arn
}

output "inline_policy_names" {
  description = "Names of created inline policies"
  value       = keys(aws_iam_role_policy.inline_policies)
}

output "instance_profile_name" {
  value = try(aws_iam_instance_profile.this[0].name, null)
}

output "instance_profile_arn" {
  value = try(aws_iam_instance_profile.this[0].arn, null)
}