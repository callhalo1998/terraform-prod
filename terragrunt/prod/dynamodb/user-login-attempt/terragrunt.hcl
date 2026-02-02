terraform {
  source = "../../../../terraform/dynamodb"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  table_name         = "prod-user-login-attempts"
  billing_mode       = "PAY_PER_REQUEST"
  hash_key           = "userId"
  hash_key_type      = "S"

  ttl_attribute_name = "ttl"
  ttl_enabled        = false

  pitr_enabled       = true
  pitr_recovery_period_in_days = 7
  
  sse_enabled        = true

  tags = {
    Environment = "prod"
    Name        = "prod-user-login-attempts"
  }
}
