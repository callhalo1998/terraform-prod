terraform {
  source = "../../../../../terraform/iam-policy"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  policy_name          = "devops-general-policy"
  policy_path          = "/"
  policy_document_json = file("devops-general-policy.json")
  tags = {
    Terraform   = "true"
  }
}