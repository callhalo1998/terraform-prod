output "cache_policy_id" {
  description = "The ID of the CloudFront cache policy"
  value       = aws_cloudfront_cache_policy.cache_policy.id
}

output "cache_policy_name" {
  description = "The name of the CloudFront cache policy"
  value       = aws_cloudfront_cache_policy.cache_policy.name
}

output "cache_policy_comment" {
  description = "The comment of the CloudFront cache policy"
  value       = aws_cloudfront_cache_policy.cache_policy.comment
}

output "cache_policy_arn" {
  value = aws_cloudfront_cache_policy.cache_policy.arn
}
