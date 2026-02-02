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
    prod-bastion-sg = {
      name        = "prod-bastion-sg"
      description = "Security group for prod-bastion-sg"
      # ingress = [
      #   {
      #     from_port       = 22
      #     to_port         = 22
      #     protocol        = "tcp"
      #     cidr_blocks     = ["113.161.55.215/32"]
      #   }
      # ]
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