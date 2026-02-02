output "secret_arns" {
  value = { for name, s in aws_secretsmanager_secret.this : name => s.arn }
}

output "secret_ids" {
  value = { for name, s in aws_secretsmanager_secret.this : name => s.id }
}

output "secret_values" {
  value = {
    for name, v in aws_secretsmanager_secret_version.this :
    name => try(jsondecode(v.secret_string), v.secret_string)
  }
  sensitive = true
}

output "secret_strings" {
  value = { for name, v in aws_secretsmanager_secret_version.this : name => v.secret_string }
  sensitive = true
}
