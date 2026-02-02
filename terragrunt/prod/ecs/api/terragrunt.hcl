terraform {
  source = "../../../../terraform/ecs/service"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "secret_manager" {
  config_path = "../../secret-manager"
}

dependency "private_subnet" {
  config_path = "../../vpc/private-subnet"
}

dependency "sg" {
  config_path = "../sg"
}

inputs = {
  # --- Service ---
  environment             = "prod"
  cluster_name            = "arn:aws:ecs:eu-west-3::cluster/prod--cluster"
  service_name            = "prod-ecs-api"
  desired_count           = 1
  subnet_ids              = [
    dependency.private_subnet.outputs.private_subnet_ids["prod-private-subnet-1"],
    dependency.private_subnet.outputs.private_subnet_ids["prod-private-subnet-2"]
  ]
  security_group_id       = dependency.sg.outputs.security_group_ids["prod-ecs-api-sg"]
  assign_public_ip        = false
  minimum_healthy_percent = 100
  maximum_percent         = 200
  network_mode            = "awsvpc"
  use_launch_type         = true
  launch_type             = "FARGATE"
  # cloudmap_service_arn    = dependency.cloudmap.outputs.cloudmap_service_arns["prod-ecs-api"]

  # service_account = {
  #   cloudmap_namespace_arn = dependency.cloudmap.outputs.cloudmap_namespace_arns["dev.patient-paths"]
  #   port_name              = "http-8080"
  # }

  # --- Task Definition ---
  load_balancers     = [
    {
      target_group_arn = "arn:aws:elasticloadbalancing:eu-west-3::targetgroup/prod-api-3001/1a1a938fcdc5ec32"
      container_port   = 3001
    }
  ]

  container_ports    = [3001]

  container_env      = {
    ASPNETCORE_ENVIRONMENT = "Production"
    NODE_ENV               = "production"
    PORT                   = "3001"
    S3_BUCKET_NAME         = "prod--app-data"
    S3_PUBLIC_BUCKET_NAME  = "prod--public-data"
    LOG_LEVEL              = "debug"
    CORS_ORIGIN            = "https://www..io"
  }

  container_image    = ".dkr.ecr.eu-west-3.amazonaws.com/prod-api:prod"
  task_cpu           = 512
  task_memory        = 1024
  execution_role_arn = "arn:aws:iam:::role/prod-ecs-execution-role-for-api"
  task_role_arn      = "arn:aws:iam:::role/prod-ecs-task-role-for-api"
  requires_compatibilities = ["FARGATE"]
  log_group_name     = "/aws/ecs/prod-ecs-api"
  region             = "eu-west-3"

  # --- Service Auto Scaling ---
  resource_id = "service/prod--cluster/prod-ecs-api"
  autoscaling = {
    enable_cpu_policy    = true
    enable_memory_policy = true
    min_capacity         = 1
    max_capacity         = 4
    cpu_target           = 75
    memory_target        = 80
    scale_in_cooldown    = 300
    scale_out_cooldown   = 120
  }
}