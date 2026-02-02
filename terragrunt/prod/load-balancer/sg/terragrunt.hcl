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
    prod-backend-alb-sg = {
      name        = "prod-backend-alb-sg"
      description = "Security group for backend ALB"
      ingress = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
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