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
# ECS Cluster
# --------------------------------------------------
resource "aws_ecs_cluster" "this" {
  name = "${var.cluster_name}"

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

# --------------------------------------------------
# ECS Capacity Provider (ASG) used this when we need EC2 instances
# --------------------------------------------------
resource "aws_ecs_capacity_provider" "this" {
  count = var.use_capacity_provider_strategy ? 1 : 0

  name = var.capacity_provider_name
  auto_scaling_group_provider {
    auto_scaling_group_arn         = var.asg_arn
    managed_termination_protection = var.managed_termination_protection

    managed_scaling {
      maximum_scaling_step_size = var.maximum_scaling_step_size
      minimum_scaling_step_size = var.minimum_scaling_step_size
      status                    = var.scaling_status
      target_capacity           = var.target_capacity
    }
  }
}

# --------------------------------------------------
# ECS Cluster Capacity Provider Binding (for services to use pre-defined aws_ecs_capacity_provider)
# --------------------------------------------------
resource "aws_ecs_cluster_capacity_providers" "this" {
  count              = var.use_capacity_provider_strategy ? 1 : 0
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = [aws_ecs_capacity_provider.this[0].name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this[0].name
    weight            = var.default_strategy_weight
  }
}

# --------------------------------------------------
# ECS Cluster Capacity Provider (FARGATE SPOT)
# --------------------------------------------------

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  count        = var.enable_fargate_capacity_providers ? 1 : 0
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategies
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight            = default_capacity_provider_strategy.value.weight
      base              = default_capacity_provider_strategy.value.base
    }
  }
}