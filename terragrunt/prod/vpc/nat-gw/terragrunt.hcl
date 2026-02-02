terraform {
  source = "../../../../terraform/vpc"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../prod-vpc"
}

dependency "public_subnet" {
  config_path = "../public-subnet"
}

inputs = {
  environment = "prod"
  vpc_id      = dependency.vpc.outputs.vpc_id
  create_nat_gateway = true

  nat_gateways = {
    prod-nat-gw-a = {
      allocation_id = dependency.vpc.outputs.eip_ids["prod-nat-gw-a"]
      subnet_id     = dependency.public_subnet.outputs.public_subnet_ids["prod-public-subnet-1"]
    }
  }
}