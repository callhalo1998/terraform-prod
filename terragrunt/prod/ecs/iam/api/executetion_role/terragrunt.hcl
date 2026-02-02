terraform {
  source = "../../../../../../terraform/iam"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  create_role          = true
  environment          = "prod"
  role_name            = "prod-ecs-execution-role-for-api"
  role_description     = "Permissions for execution role"
  assume_role_policy   = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  create_inline_policy = true

  inline_policies = {
    api_execution_role  = file("api_execution_role.json")
  }

  attached_policies = {
    ec2_full = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  }
}