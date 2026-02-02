terraform {
  source = "../../../terraform/ecr"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  repository_name       = "prod-api"
  image_tag_mutability  = "MUTABLE"
  force_delete          = false
  encryption_type       = "AES256"
  environment           = "prod"

  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 5 images",
        selection    = {
          tagStatus     = "any",
          countType     = "imageCountMoreThan",
          countNumber   = 5
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  scan_type = "ENHANCED"
  scan_rules = [
    {
      scan_frequency = "SCAN_ON_PUSH"
      filter         = "prod-api"
    }
  ]
}