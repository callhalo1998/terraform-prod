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
# IAM Role
# ------------------------------------------------------------------------------
resource "aws_iam_role" "this" {
  count              = var.create_role ? 1 : 0
  name               = var.role_name
  assume_role_policy = var.assume_role_policy
  description        = var.role_description
  path               = var.role_path
  tags = {
    Name        = "${var.role_name}"
    Environment = var.environment
    Terraform   = "true"
  }
}

# ------------------------------------------------------------------------------
# IAM Inline Policy (custom)
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy" "inline_policies" {
  for_each = var.create_inline_policy ? var.inline_policies : {}
  name     = each.key
  role     = aws_iam_role.this[0].name
  policy   = each.value
}

# ------------------------------------------------------------------------------
# Attach AWS managed policies (or any external custom policies)
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "managed_attach" {
  for_each = var.create_role ? var.attached_policies : {}
  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

# ------------------------------------------------------------------------------
# IAM Instance Profile (EC2 only)
# ------------------------------------------------------------------------------

resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = coalesce(
    var.instance_profile_name,
    try(aws_iam_role.this[0].name, var.role_name)
  )

  path = var.instance_profile_path

  role = try(aws_iam_role.this[0].name, var.role_name)
}