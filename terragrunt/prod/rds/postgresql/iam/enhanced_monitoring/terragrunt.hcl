terraform {
  source = "../../../../../../terraform/iam"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  create_role          = true
  environment          = "prod"
  role_name            = "prod-rds-enhanced-monitoring"
  role_description     = "Permissions for rds-enhanced-monitoring"
  assume_role_policy   = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  create_inline_policy = false

  attached_policies = {
    enhanced_monitoring = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  }
}