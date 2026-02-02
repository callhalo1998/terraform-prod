terraform {
  source = "../../../../terraform/load-balancer"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "vpc" {
  config_path = "../../vpc/prod-vpc"
}

dependency "public_subnet" {
  config_path = "../../vpc/public-subnet"
}

dependency "sg" {
  config_path = "../sg"
}

inputs = {
  name               = "prod-api-alb"
  internal           = false
  load_balancer_type = "application"
  environment        = "prod"

  subnet_ids = [
    dependency.public_subnet.outputs.public_subnet_ids["prod-public-subnet-1"],
    dependency.public_subnet.outputs.public_subnet_ids["prod-public-subnet-2"]
  ]

  security_group_ids = [dependency.sg.outputs.security_group_ids["prod-backend-alb-sg"]]
  vpc_id             = dependency.vpc.outputs.vpc_id

  target_groups = [
    {
      name                          = "prod-api-3001"
      port                          = 3001
      protocol                      = "HTTP"
      health_check_enabled          = true
      health_check_protocol         = "HTTP"
      health_check_path             = "/api/health-check"
      target_type                   = "ip"
    }
  ]

  listeners = [
    {
      name                      = "prod-api-80"
      port                      = 80
      protocol                  = "HTTP"
      default_target_group_name = "prod-api-3001"
    },
    {
      name                      = "prod-api-443"
      port                      = 443
      protocol                  = "HTTPS"
      default_target_group_name = "prod-api-3001"
      certificate_arn           = "arn:aws:acm:eu-west-3:458409717942:certificate/9d3b747a-187b-40bd-9d4d-7f19aff39e41"
    }
  ]

  listener_rules = [
    {
      listener_name = "prod-api-80"
      priority      = 10
      conditions = [
        { 
          type   = "path_pattern",
          values = ["/api/*"]
        },
        { type   = "host_header",
          values = ["*..io"]
        }
      ]
      actions = [
        {
          type = "forward",
          target_group_name = "prod-api-3001"
        }
      ]
    }
  ]
}