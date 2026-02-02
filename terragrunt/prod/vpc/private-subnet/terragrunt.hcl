terraform {
  source = "../../../../terraform/vpc"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../prod-vpc"
}

dependency "nat-gw" {
  config_path = "../nat-gw"
}

inputs = {
  environment    = "prod"
  vpc_id         = dependency.vpc.outputs.vpc_id
  private_subnets = {
    prod-private-subnet-1 = {
      cidr_block  = "10.10.1.0/24"
      az          = "eu-west-3a"
      route_table = "private-rt"
    }
    prod-private-subnet-2 = {
      cidr_block  = "10.10.2.0/24"
      az          = "eu-west-3b"
      route_table = "private-rt"
    }
    prod-database-subnet-1 = {
      cidr_block  = "10.10.3.0/24"
      az          = "eu-west-3a"
    }
    prod-database-subnet-2 = {
      cidr_block  = "10.10.4.0/24"
      az          = "eu-west-3b"
    }
  }

  route_tables = {
    private-rt = {
      routes = [
        {
          destination_cidr_block = "0.0.0.0/0"
          target_type            = "nat_gateway"
          target_id              = dependency.nat-gw.outputs.nat_gateway_ids["prod-nat-gw-a"]
        }
      ]
    }
  }
}