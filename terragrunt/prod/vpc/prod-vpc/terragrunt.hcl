terraform {
  source = "../../../../terraform/vpc"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  environment        = "prod"
  create_vpc         = true
  vpc_cidr           = "10.10.0.0/16"
  create_igw         = true
  eips_to_create     = ["prod-bastion","prod-nat-gw-a"]
}