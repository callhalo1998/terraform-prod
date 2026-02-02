terraform {
  source = "../../../../terraform/api-gateway/http-api"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "private_subnet" {
  config_path = "../../vpc/private-subnet"
}

inputs = {
  name        = "prod-http-api"
  description = "HTTP API for backend"

  stages = {
    prod = {
      name               = "prod"
      auto_deploy        = true
      detailed_metrics   = true
      access_log_enabled = true
      access_log_destination = "arn:aws:logs:eu-west-3::log-group:/aws/http-api/access-log:*"
      access_log_format      = "$context.requestId $context.status"
    }
  }

  routes = [
    vpc_link_id = dependency.vpc_link.outputs.vpc_link_ids["private-nlb"]
    {
      route_key                = "ANY /{proxy+}"
      integration_type         = "HTTP_PROXY"
      integration_method       = "ANY"
      integration_uri          = "arn-listener"
      connection_type          = "VPC_LINK"
      request_parameters = {
        "overwrite:path" = "$request.path"
      }
      timeout_ms               = 20000
    },
    {
      route_key                = "ANY /"
      integration_type         = "HTTP_PROXY"
      integration_method       = "ANY"
      integration_uri          = "arn-listener"
      connection_type          = "VPC_LINK"
      request_parameters = {
        "overwrite:path" = "$request.path"
      }
      timeout_ms               = 20000
    }
  ]

  tags = {
    Terraform = "true"
    Env       = "prod"
  }
}