output "vpc_id" {
  value = try(aws_vpc.this[0].id, null)
}

output "igw_id" {
  value       = try(aws_internet_gateway.this[0].id, null)
  description = "The ID of the Internet Gateway"
}

output "nat_gateway_ids" {
  value = {
    for k, nat in aws_nat_gateway.this : k => nat.id
  }
}

output "eip_ids" {
  value = {
    for k, eip in aws_eip.this : k => eip.id
  }
}

output "public_subnet_ids" {
  value = {
    for k, subnet in aws_subnet.public : k => subnet.id
  }
}

output "private_subnet_ids" {
  value = {
    for k, subnet in aws_subnet.private : k => subnet.id
  }
}

output "subnets" {
  description = "Map of all subnet IDs"
  value = merge(
    { for k, s in aws_subnet.private : k => s.id },
    { for k, s in aws_subnet.public  : k => s.id }
  )
}