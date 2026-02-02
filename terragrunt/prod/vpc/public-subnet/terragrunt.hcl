terraform {
  source = "../../../../terraform/vpc"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../prod-vpc"
}

inputs = {
  environment = "prod"
  vpc_id      = dependency.vpc.outputs.vpc_id
  igw_id      = dependency.vpc.outputs.igw_id

  public_subnets = {
    prod-public-subnet-1 = {
      cidr_block  = "10.10.5.0/24"
      az          = "eu-west-3a"
      route_table = "public-rt"
    }
    prod-public-subnet-2 = {
      cidr_block  = "10.10.6.0/24"
      az          = "eu-west-3b"
      route_table = "public-rt"
    }
  }

  route_tables = {
    public-rt = {
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          target_type            = "igw"
          target_id              = dependency.vpc.outputs.igw_id
        }
      ]
    }
  }
}