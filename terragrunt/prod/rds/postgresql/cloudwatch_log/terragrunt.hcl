terraform {
  source = "../../../../../terraform/cloudwatch-log-group"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  environment = "prod"

  log_groups = {
    prod--postgres = {
      name              = "/aws/rds/instance/prod--postgres/postgresql"
      retention_in_days = 14
    }
  }
}
