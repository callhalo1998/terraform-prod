output "lb_arn" {
  description = "ARN of the Load Balancer"
  value       = aws_lb.this.arn
}

output "lb_name" {
  description = "Name of the Load Balancer"
  value       = aws_lb.this.name
}

output "lb_dns_name" {
  description = "DNS name of the Load Balancer"
  value       = aws_lb.this.dns_name
}

output "lb_zone_id" {
  description = "Hosted zone ID of the Load Balancer"
  value       = aws_lb.this.zone_id
}

output "target_group_arns" {
  description = "Map of target group ARNs keyed by target group name"
  value       = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}

output "target_group_names" {
  description = "Map of target group names keyed by target group name"
  value       = { for k, tg in aws_lb_target_group.this : k => tg.name }
}

output "listeners" {
  description = "Map of listeners keyed by listener name with ARN/port/protocol"
  value = merge(
    { for name, l in aws_lb_listener.plain  : name => { arn = l.arn,  port = l.port, protocol = l.protocol } },
    { for name, l in aws_lb_listener.secure : name => { arn = l.arn,  port = l.port, protocol = l.protocol } }
  )
}

output "listener_arns" {
  description = "Map of listener ARNs keyed by listener name"
  value = merge(
    { for name, l in aws_lb_listener.plain  : name => l.arn },
    { for name, l in aws_lb_listener.secure : name => l.arn }
  )
}

output "listener_rules" {
  description = "Map of listener rules keyed by <listener_name>-<priority>"
  value = {
    for k, r in aws_lb_listener_rule.this :
    k => {
      id            = r.id
      priority      = r.priority
      listener_arn  = r.listener_arn
    }
  }
}
