terraform {
  backend "s3" {}
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

# --------------------------------------------------
# ECS Task Definition
# --------------------------------------------------
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.service_name}"
  requires_compatibilities = var.requires_compatibilities
  network_mode             = var.network_mode
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = var.service_name
      image = var.container_image

      cpu    = var.task_cpu
      memory = var.task_memory

      portMappings = [
        for p in (var.container_ports != null
          ? var.container_ports
          : (var.container_port != null ? [var.container_port] : [])
        ) : {
          containerPort = tonumber(p)
          name          = "http-${p}"
          hostPort      = var.network_mode == "bridge" ? 0 : tonumber(p)
          protocol      = "tcp"
        }
      ]

      environment = [
        for key, value in (var.container_env != null ? tomap(var.container_env) : {}) : {
          name  = key
          value = value
        }
      ]

      secrets = [
        for name, cfg in (var.container_secrets != null ? var.container_secrets : {}) : {
          name = name
          valueFrom = (
            can(cfg.key) && cfg.key != null && cfg.key != "" ?
            "${cfg.arn}:${cfg.key}::" :
            "${cfg.arn}::"
          )
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.region
          awslogs-stream-prefix = var.service_name
        }
      }
    }
  ])
}

# --------------------------------------------------
# ECS Service (BLUE/GREEN disabled by default)
# --------------------------------------------------
resource "aws_ecs_service" "this" {
  name            = "${var.service_name}"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count

  dynamic "capacity_provider_strategy" {
    for_each = var.use_capacity_provider_strategy ? var.capacity_provider_strategy : []
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = lookup(capacity_provider_strategy.value, "base", null)
    }
  }

  launch_type = var.use_launch_type ? var.launch_type : null

  dynamic "network_configuration" {
    for_each = var.network_mode != "bridge" ? [1] : []
    content {
      subnets         = var.subnet_ids
      security_groups = [var.security_group_id]
      assign_public_ip = var.assign_public_ip
    }
  }

  dynamic "deployment_controller" {
    for_each = var.enable_blue_green ? [1] : []
    content {
      type = "CODE_DEPLOY"
    }
  }

  dynamic "load_balancer" {
    for_each = length(var.load_balancers) > 0 ? var.load_balancers : (
      var.target_group_arn != null && var.container_port != null
        ? [{ target_group_arn = var.target_group_arn, container_port = var.container_port }]
        : []
    )

    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = var.service_name
      container_port = lookup(load_balancer.value, "container_port", var.container_port)
    }
  }

  dynamic "service_registries" {
    for_each = var.cloudmap_service_arn != null ? [1] : []
    content {
      registry_arn = var.cloudmap_service_arn
    }
  }

  dynamic "service_connect_configuration" {
    for_each = var.service_account != null ? [1] : []
    content {
      enabled   = true
      namespace = var.service_account.cloudmap_namespace_arn

      service {
        port_name = var.service_account.port_name
      }
    }
  }

  deployment_minimum_healthy_percent = var.minimum_healthy_percent
  deployment_maximum_percent         = var.maximum_percent

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# --------------------------------------------------
# ECS Service Auto Scaling
# --------------------------------------------------

resource "aws_appautoscaling_target" "ecs_service" {
  for_each = var.autoscaling == null ? {} : { this = var.autoscaling }

  service_namespace  = "ecs"
  resource_id        = var.resource_id
  scalable_dimension = "ecs:service:DesiredCount"

  min_capacity = each.value.min_capacity
  max_capacity = each.value.max_capacity
}

resource "aws_appautoscaling_policy" "cpu" {
  for_each = var.autoscaling != null && try(var.autoscaling.enable_cpu_policy, true) ? { this = var.autoscaling } : {}

  name               = "cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs_service["this"].service_namespace
  resource_id        = aws_appautoscaling_target.ecs_service["this"].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service["this"].scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value = try(each.value.cpu_target, 70)
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = try(each.value.scale_in_cooldown, 60)
    scale_out_cooldown = try(each.value.scale_out_cooldown, 60)
  }
}

resource "aws_appautoscaling_policy" "memory" {
  for_each = var.autoscaling != null && try(var.autoscaling.enable_memory_policy, true) ? { this = var.autoscaling } : {}

  name               = "memory-scaling"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs_service["this"].service_namespace
  resource_id        = aws_appautoscaling_target.ecs_service["this"].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service["this"].scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value = try(each.value.memory_target, 75)
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_in_cooldown  = try(each.value.scale_in_cooldown, 60)
    scale_out_cooldown = try(each.value.scale_out_cooldown, 60)
  }
}
