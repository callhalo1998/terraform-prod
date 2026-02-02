terraform {
  source = "../../../../terraform/sg"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../../vpc/prod-vpc"
}

inputs = {
  vpc_id      = dependency.vpc.outputs.vpc_id
  environment = "prod"

  security_groups = {
    prod-vpc-link = {
      name        = "prod-vpc-link"
      description = "prod-vpc-link sg towards ECS backend"
      ingress = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          security_groups = ["sg-086847e541ec14f99"]
        }
      ]
      egress = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
  }
}