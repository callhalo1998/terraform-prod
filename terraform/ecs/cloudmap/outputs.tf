output "cloudmap_service_arns" {
  value = {
    for k, svc in aws_service_discovery_service.this :
    svc.name => svc.arn
  }
}

output "cloudmap_namespace_arns" {
  value = {
    for k, ns in aws_service_discovery_private_dns_namespace.this :
    ns.name => ns.arn
  }
}