terraform {
  source = "../../../terraform/secret-manager"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  environment = "prod"
  secrets     = {
    "prod-backend-secrets" = {
        secrets = yamldecode(sops_decrypt_file("prod-backend-secrets.enc.yaml"))
    }
  }
}