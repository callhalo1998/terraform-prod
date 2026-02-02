terraform {
  source = "../../../terraform/identity-center"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "iam" {
  config_path = "../iam/dev-member/general-policy"
}

inputs = {
  sso_home_region = "eu-west-3"

  groups = [
    {
      display_name = "devops-group"
      description  = "group for devops"
    },
    {
      display_name = "dev-group"
      description  = "group for dev"
    }
  ]

  users = [
    {
      user_name    = "khanh.duong"
      given_name   = "Khanh"
      family_name  = "Duong"
      email        = "khanh.duong@saigontechnology.com"
      display_name = "Khanh Duong"
      groups       = ["devops-group"]
    }
  ]

  permission_sets = {
    delegated_administrator = {
      aws_managed_policy = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    }

    dev_permission_set = {
      customer_policies = [
        # "test-policy", 
        dependency.iam.outputs.policy_name_map["dev-general-policy"]
      ]
      # aws_managed_policy = [
      #   "arn:aws:iam::aws:policy/AmazonRekognitionFullAccess"
      # ]
    }
  }

  account_assignments = {
    devops_admin = {
      principal_type  = "GROUP"
      principal_name  = "devops-group"
      account_ids     = [""]
      permission_sets = ["delegated_administrator"]
    }
    dev_member = {
      principal_type  = "GROUP"
      principal_name  = "dev-group"
      account_ids     = [""]
      permission_sets = ["dev_permission_set"]
    }
  }
}