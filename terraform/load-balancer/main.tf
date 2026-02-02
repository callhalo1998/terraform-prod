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

# ------------------------------------------------------------------------------
# Load balancer
# ------------------------------------------------------------------------------

resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = var.load_balancer_type  # "application" (ALB) OR "network" (NLB)
  subnets            = var.subnet_ids
  security_groups    = var.load_balancer_type == "application" ? var.security_group_ids : null

  tags = merge(
    {
      Name        = var.name
      Environment = var.environment
      Terraform   = true
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# Target group
# ------------------------------------------------------------------------------

resource "aws_lb_target_group" "this" {
  for_each    = { for tg in var.target_groups : tg.name => tg }
  name        = each.value.name
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = coalesce(each.value.target_type, var.target_type)
  deregistration_delay = var.deregistration_delay
  health_check {
    enabled             = each.value.health_check_enabled
    protocol            = each.value.health_check_protocol
    path                = each.value.health_check_protocol == "HTTP" ? try(each.value.health_check_path, null) : null
    interval            = each.value.health_check_interval
    timeout             = each.value.health_check_timeout
    healthy_threshold   = each.value.health_check_healthy_threshold
    unhealthy_threshold = each.value.health_check_unhealthy_threshold
    matcher             = each.value.health_check_protocol == "HTTP" ? try(each.value.health_check_matcher, null) : null
  }
}

# ------------------------------------------------------------------------------
# LISTENER WITHOUT CERTIFICATES (HTTP)
# ------------------------------------------------------------------------------
resource "aws_lb_listener" "plain" {
  for_each          = { for l in var.listeners : l.name => l if !(contains(["HTTPS","TLS"], upper(l.protocol))) }
  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = upper(each.value.protocol)

  # --- Case 1: forward single target group ---
  dynamic "default_action" {
    for_each = (
      try(each.value.default_target_group_name, null) != null &&
      contains(keys(aws_lb_target_group.this), each.value.default_target_group_name)
    ) ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[each.value.default_target_group_name].arn
    }
  }

  # --- Case 2: forward many target group (weighted) ---
  dynamic "default_action" {
    for_each = length(try(each.value.target_groups, [])) > 0 ? [1] : []
    content {
      type = "forward"
      forward {
        dynamic "target_group" {
          for_each = { for tg in each.value.target_groups : tg.name => try(tg.weight, null) }
          content {
            arn    = aws_lb_target_group.this[target_group.key].arn
            weight = try(target_group.value, null)
          }
        }
        dynamic "stickiness" {
          for_each = try([each.value.stickiness], [])
          content {
            enabled  = try(stickiness.value.enabled, false)
            duration = try(stickiness.value.duration, 1)
          }
        }
      }
    }
  }
}

# ------------------------------------------------------------------------------
# LISTENER WITH CERTIFICATES (HTTPS)
# ------------------------------------------------------------------------------
resource "aws_lb_listener" "secure" {
  for_each          = { for l in var.listeners : l.name => l if contains(["HTTPS","TLS"], upper(l.protocol)) }
  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = upper(each.value.protocol)

  ssl_policy     = try(each.value.ssl_policy, null)
  certificate_arn = each.value.certificate_arn # REQUIRED cho HTTPS/TLS

  # --- Case 1: forward single target group ---
  dynamic "default_action" {
    for_each = (
      try(each.value.default_target_group_name, null) != null &&
      contains(keys(aws_lb_target_group.this), each.value.default_target_group_name)
    ) ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.this[each.value.default_target_group_name].arn
    }
  }

  # --- Case 2: forward many target group (weighted) ---
  dynamic "default_action" {
    for_each = length(try(each.value.target_groups, [])) > 0 ? [1] : []
    content {
      type = "forward"
      forward {
        dynamic "target_group" {
          for_each = { for tg in each.value.target_groups : tg.name => try(tg.weight, null) }
          content {
            arn    = aws_lb_target_group.this[target_group.key].arn
            weight = try(target_group.value, null)
          }
        }
        dynamic "stickiness" {
          for_each = try([each.value.stickiness], [])
          content {
            enabled  = try(stickiness.value.enabled, false)
            duration = try(stickiness.value.duration, 1)
          }
        }
      }
    }
  }
}

# ------------------------------------------------------------------------------
# LISTENER RULE
# ------------------------------------------------------------------------------

resource "aws_lb_listener_rule" "this" {
  for_each = {
    for rule in var.listener_rules : "${rule.listener_name}-${rule.priority}" => rule
  }

  # support both HTTP/HTTPS listener
  listener_arn = coalesce(
    try(aws_lb_listener.plain[each.value.listener_name].arn, null),
    try(aws_lb_listener.secure[each.value.listener_name].arn, null)
  )

  priority = each.value.priority

  # path_pattern
  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if try(c.type, "path_pattern") == "path_pattern"]
    content {
      path_pattern {
        values = condition.value.values
      }
    }
  }

  # host_header
  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if try(c.type, null) == "host_header"]
    content {
      host_header {
        values = condition.value.values
      }
    }
  }

  # http_request_method
  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if try(c.type, null) == "http_request_method"]
    content {
      http_request_method {
        values = condition.value.values
      }
    }
  }

  # source_ip
  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if try(c.type, null) == "source_ip"]
    content {
      source_ip {
        values = condition.value.values
      }
    }
  }

  # http_header
  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if try(c.type, null) == "http_header"]
    content {
      http_header {
        http_header_name = condition.value.http_header_name
        values           = condition.value.values
      }
    }
  }

  # query_string
  dynamic "condition" {
    for_each = [for c in each.value.conditions : c if try(c.type, null) == "query_string"]
    content {
      dynamic "query_string" {
        for_each = try(condition.value.query_strings, [])
        content {
          key   = try(query_string.value.key, null)
          value = try(query_string.value.value, null)
        }
      }
    }
  }

  # action
  dynamic "action" {
    for_each = try(each.value.actions, [])
    content {
      type             = action.value.type
      target_group_arn = aws_lb_target_group.this[action.value.target_group_name].arn
    }
  }
}