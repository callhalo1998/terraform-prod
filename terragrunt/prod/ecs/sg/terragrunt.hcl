terraform {
  source = "../../../../terraform/sg"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../../vpc/prod-vpc"
}

dependency "sg" {
  config_path = "../../load-balancer/sg"
}

inputs = {
  vpc_id      = dependency.vpc.outputs.vpc_id
  environment = "prod"

  security_groups = {
    # BACKEND
    prod-ecs-api-sg = {
      name        = "prod-ecs-api-sg"
      description = "Security group for prod-ecs-api"
      ingress = [
        {
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          security_groups = [dependency.sg.outputs.security_group_ids["prod-backend-alb-sg"]]
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