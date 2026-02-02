terraform {
  source = "../../../../terraform/iam"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  create_role          = true
  environment          = "prod"
  role_name            = "prod-bastion-role"
  role_description     = "Permissions for bastion host"
  assume_role_policy   = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  create_instance_profile = true
  create_inline_policy    = true

  inline_policies = {
    prod-bastion = file("prod-bastion.json")
  }

  attached_policies = {
    ssm_session       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}