output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "capacity_provider_name" {
  description = "The name of the ECS capacity provider (if created)"
  value       = var.use_capacity_provider_strategy ? aws_ecs_capacity_provider.this[0].name : null
}
