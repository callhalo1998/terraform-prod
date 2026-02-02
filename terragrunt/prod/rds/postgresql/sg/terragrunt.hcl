terraform {
  source = "../../../../../terraform/sg"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../../../vpc/prod-vpc"
}

dependency "sg-ecs" {
  config_path = "../../../ecs/sg"
}

dependency "sg-bastion" {
  config_path = "../../../ec2/sg"
}

inputs = {
  vpc_id      = dependency.vpc.outputs.vpc_id
  environment = "prod"

  security_groups = {
    # RDS
    prod-postgresql-sg = {
      name        = "prod-postgresql-sg"
      description = "Security group for prod-postgresql"
      ingress = [
        {
          from_port   = 5432
          to_port     = 5432
          protocol    = "tcp"
          security_groups = [dependency.sg-ecs.outputs.security_group_ids["prod-ecs-api-sg"]]
        },
        {
          from_port       = 5432
          to_port         = 5432
          protocol        = "tcp"
          security_groups = [dependency.sg-bastion.outputs.security_group_ids["prod-bastion-sg"]]
        }
      ]
    }
  }
}