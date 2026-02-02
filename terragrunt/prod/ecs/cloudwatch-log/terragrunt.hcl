terraform {
  source = "../../../../terraform/cloudwatch-log-group"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  environment = "prod"

  log_groups = {
    prod-ecs-backend-1 = {
      name              = "/aws/ecs/prod-ecs-api"
      retention_in_days = 14
    }
  }
}