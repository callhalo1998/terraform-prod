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
# VPC
# ------------------------------------------------------------------------------

resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name        = "${var.environment}-vpc"
      Terraform   = "true"
    },
    var.tags
  )
}

resource "aws_internet_gateway" "this" {
  count  = var.create_igw ? 1 : 0
  vpc_id = aws_vpc.this[0].id

  tags = merge(
    {
      Name        = "${var.environment}-igw"
      Terraform   = "true"
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# EIP
# ------------------------------------------------------------------------------

resource "aws_eip" "this" {
  for_each = toset(var.eips_to_create)
  domain   = "vpc"

  tags = merge(
    {
      Name        = "${each.key}"
      Terraform   = "true"
    },
    try(each.value.tags, {}),
    var.tags
  )
}

# ------------------------------------------------------------------------------
# NAT GATEWAY
# ------------------------------------------------------------------------------

resource "aws_nat_gateway" "this" {
  for_each = var.create_nat_gateway ? var.nat_gateways : {}

  allocation_id = try(each.value.allocation_id, null)
  subnet_id     = each.value.subnet_id

  tags = merge(
    {
      Name        = "${each.key}"
      Terraform   = "true"
    },
    try(each.value.tags, {}),
    var.tags
  )
}

# ------------------------------------------------------------------------------
# PUBLIC SUBNETS
# ------------------------------------------------------------------------------

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = merge(
    {
      Name        = "${each.key}"
      Terraform   = "true"
    },
    try(each.value.tags, {}),
    var.tags
  )
}

# ------------------------------------------------------------------------------
# PRIVATE SUBNETS
# ------------------------------------------------------------------------------

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az

  tags = merge(
    {
      Name        = "${each.key}"
      Terraform   = "true"
    },
    try(each.value.tags, {}),
    var.tags
  )
}

# ------------------------------------------------------------------------------
# ROUTE TABLES
# ------------------------------------------------------------------------------

resource "aws_route_table" "this" {
  for_each = var.route_tables

  vpc_id = var.vpc_id

  tags = merge(
    {
      Name        = "${var.environment}-${each.key}"
      Terraform   = "true"
    },
    try(each.value.tags, {}),
    var.tags
  )
}

resource "aws_route" "custom" {
  for_each = {
    for route in flatten([
      for table_key, table in var.route_tables : [
        for idx, route in table.routes : {
          route_key  = "${table_key}-${idx}"
          table_key  = table_key
          route      = route
        }
      ]
    ]) : route.route_key => route
  }

  route_table_id         = aws_route_table.this[each.value.table_key].id
  destination_cidr_block = each.value.route.destination_cidr_block

  gateway_id                = try(each.value.route.target_type == "igw" ? each.value.route.target_id : null, null)
  nat_gateway_id            = try(each.value.route.target_type == "nat_gateway" ? each.value.route.target_id : null, null)
  vpc_peering_connection_id = try(each.value.route.target_type == "vpc_peering" ? each.value.route.target_id : null, null)
  network_interface_id      = try(each.value.route.target_type == "eni" ? each.value.route.target_id : null, null)
}

# ------------------------------------------------------------------------------
# ROUTE TABLE ASSOCIATIONS
# ------------------------------------------------------------------------------

resource "aws_route_table_association" "public" {
  for_each = {
    for subnet_key, subnet in var.public_subnets :
    subnet_key => {
      subnet_id      = aws_subnet.public[subnet_key].id
      route_table_id = lookup(subnet, "route_table", null)
    }
    if contains(keys(subnet), "route_table")
  }

  subnet_id      = each.value.subnet_id
  route_table_id = aws_route_table.this[each.value.route_table_id].id
}

resource "aws_route_table_association" "private" {
  for_each = {
    for subnet_key, subnet in var.private_subnets :
    subnet_key => {
      subnet_id      = aws_subnet.private[subnet_key].id
      route_table_id = lookup(subnet, "route_table", null)
    }
    if contains(keys(subnet), "route_table")
  }

  subnet_id      = each.value.subnet_id
  route_table_id = aws_route_table.this[each.value.route_table_id].id
}

# ------------------------------------------------------------------------------
# NACL
# ------------------------------------------------------------------------------

resource "aws_network_acl" "this" {
  for_each = var.create_nacl ? var.nacls : {}

  vpc_id = var.vpc_id

  tags = merge(
    {
      Name        = "${var.environment}-${each.key}"
      Terraform   = "true"
    },
    try(each.value.tags, {}),
    var.tags
  )
}

resource "aws_network_acl_rule" "ingress" {
  for_each = {
    for pair in flatten([
      for nacl_key, nacl in var.nacls : [
        for rule in nacl.ingress : {
          key        = "${nacl_key}-ingress-${rule.rule_number}"
          nacl_id    = nacl_key
          rule_data  = rule
        }
      ]
    ]) : pair.key => pair
  }

  network_acl_id = aws_network_acl.this[each.value.nacl_id].id
  rule_number    = each.value.rule_data.rule_number
  egress         = false
  protocol       = each.value.rule_data.protocol
  rule_action    = each.value.rule_data.rule_action
  cidr_block     = each.value.rule_data.cidr_block
  from_port      = each.value.rule_data.from_port
  to_port        = each.value.rule_data.to_port
}

resource "aws_network_acl_rule" "egress" {
  for_each = {
    for pair in flatten([
      for nacl_key, nacl in var.nacls : [
        for rule in nacl.egress : {
          key        = "${nacl_key}-egress-${rule.rule_number}"
          nacl_id    = nacl_key
          rule_data  = rule
        }
      ]
    ]) : pair.key => pair
  }

  network_acl_id = aws_network_acl.this[each.value.nacl_id].id
  rule_number    = each.value.rule_data.rule_number
  egress         = true
  protocol       = each.value.rule_data.protocol
  rule_action    = each.value.rule_data.rule_action
  cidr_block     = each.value.rule_data.cidr_block
  from_port      = each.value.rule_data.from_port
  to_port        = each.value.rule_data.to_port
}


resource "aws_network_acl_association" "this" {
  for_each = {
    for pair in flatten([
      for nacl_key, nacl in var.nacls : [
        for subnet_name, subnet_id in nacl.subnet_ids : {
          key       = "${nacl_key}-${subnet_name}"
          nacl_id   = nacl_key
          subnet_id = subnet_id
        }
      ]
    ]) : pair.key => pair
  }

  network_acl_id = aws_network_acl.this[each.value.nacl_id].id
  subnet_id      = each.value.subnet_id
}

