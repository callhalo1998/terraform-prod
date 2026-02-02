terraform {
  source = "../../../../terraform/api-gateway/vpc-link"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "private-subnet" {
  config_path = "../../vpc/prod-vpc"
}

dependency "sg" {
  config_path = "../sg"
}

inputs = {
  vpc_links = {
    prod-vpclink = {
      subnet_ids              = [
        dependency.private_subnet.outputs.private_subnet_ids["prod-private-subnet-1"],
        dependency.private_subnet.outputs.private_subnet_ids["prod-private-subnet-2"]
    ]
      security_group_ids = ["sg-0126a761720de5883"]
    }
  }
  
  tags = {
    Terraform = "true"
    Env       = "prod"
  }
}