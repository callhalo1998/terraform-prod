output "security_group_ids" {
  description = "Map of security group IDs"
  value = {
    for key, sg in aws_security_group.this :
    key => sg.id
  }
}

output "sg_ssgr" {
  value = aws_security_group.this
}

output "sg_cidr" {
  value = aws_security_group.this
}