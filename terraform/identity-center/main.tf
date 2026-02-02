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

provider "aws" {
  alias  = "sso"
  region = var.sso_home_region
}

# ------------------------------------------------------------------------------
# Check AWS Organization & Identity Center enabled or not
# ------------------------------------------------------------------------------

data "aws_organizations_organization" "this" {
  provider = aws.sso
}

# ------------------------------------------------------------------------------
# Users / Groups
# ------------------------------------------------------------------------------

data "aws_ssoadmin_instances" "this" {
  provider = aws.sso
}

resource "aws_identitystore_group" "this" {
  provider          = aws.sso
  for_each          = { for g in var.groups : g.display_name => g }
  identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]
  display_name      = each.key
  description       = try(each.value.description, null)
}

resource "aws_identitystore_user" "this" {
  provider          = aws.sso
  for_each          = { for u in var.users : u.user_name => u }
  identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]

  user_name    = each.value.user_name
  display_name = try(each.value.display_name, null)

  name {
    given_name  = each.value.given_name
    family_name = each.value.family_name
  }

  emails {
    value = each.value.email
    primary = true
    type    = "work"
  }
}

resource "aws_identitystore_group_membership" "this" {
  provider          = aws.sso
  identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]

  for_each = {
    for pair in flatten([
      for u in var.users : [
        for g in u.groups : {
          key        = "${u.user_name}:${g}"
          user_name  = u.user_name
          group_name = g
        }
      ]
    ]) : pair.key => pair
  }

  group_id  = aws_identitystore_group.this[each.value.group_name].group_id
  member_id = aws_identitystore_user.this[each.value.user_name].user_id
}

# ------------------------------------------------------------------------------
# Permission Sets
# ------------------------------------------------------------------------------

resource "aws_ssoadmin_permission_set" "this" {
  provider      = aws.sso
  for_each      = var.permission_sets
  instance_arn  = data.aws_ssoadmin_instances.this.arns[0]

  name             = each.key
  description      = try(each.value.description, null)
  session_duration = try(each.value.session_duration, null)
  tags             = try(each.value.tags, null)
}

resource "aws_ssoadmin_managed_policy_attachment" "this_aws" {
  provider = aws.sso
  for_each = {
    for pair in flatten([
      for ps_name, cfg in var.permission_sets : [
        for arn in try(coalesce(cfg.aws_managed_policy, []), []) : {
          key = "${ps_name}:${arn}", ps = ps_name, arn = arn
        }
      ]
    ]) : pair.key => pair
  }

  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.ps].arn
  managed_policy_arn = each.value.arn
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "this_cust" {
  provider = aws.sso
  for_each = {
    for pair in flatten([
      for ps_name, cfg in var.permission_sets : [
        for name in try(coalesce(cfg.customer_policies, []), []) : {
          key = "${ps_name}:${name}", ps = ps_name, name = name
        }
      ]
    ]) : pair.key => pair
  }

  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.ps].arn

  customer_managed_policy_reference {
    name = each.value.name
    path = "/"
  }
}

# ------------------------------------------------------------------------------
# Account Assignments
# ------------------------------------------------------------------------------

data "aws_identitystore_group" "assign_group" {
  provider          = aws.sso
  for_each = toset([
    for _, v in var.account_assignments : v.principal_name
    if upper(v.principal_type) == "GROUP"
    && !contains([for g in var.groups : g.display_name], v.principal_name)
  ])
  identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "displayName"
      attribute_value = each.value
    }
  }
}

data "aws_identitystore_user" "assign_user" {
  provider          = aws.sso
  for_each = toset([
    for _, v in var.account_assignments : v.principal_name
    if upper(v.principal_type) == "USER"
    && !contains([for u in var.users : u.email], v.principal_name)
  ])
  identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "emails.value"
      attribute_value = each.value
    }
  }
}

resource "aws_ssoadmin_account_assignment" "this" {
  provider = aws.sso
  for_each = {
    for item in flatten([
      for name, a in var.account_assignments : [
        for acc in a.account_ids : [
          for ps in a.permission_sets : {
            key              = "${name}:${acc}:${ps}"
            account_id       = acc
            permission_set   = ps
            principal_type_u = upper(a.principal_type)
            principal_name   = a.principal_name
          }
        ]
      ]
    ]) : item.key => item
  }

  instance_arn       = data.aws_ssoadmin_instances.this.arns[0]
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn
  target_type        = "AWS_ACCOUNT"
  target_id          = each.value.account_id
  principal_type     = each.value.principal_type_u

  principal_id = each.value.principal_type_u == "GROUP" ? (
      contains(keys(aws_identitystore_group.this), each.value.principal_name)
      ? aws_identitystore_group.this[each.value.principal_name].group_id
      : data.aws_identitystore_group.assign_group[each.value.principal_name].group_id
    ) : (
      contains([for u in var.users : u.email], each.value.principal_name)
      ? aws_identitystore_user.this[
          element([for u in var.users : u.user_name if u.email == each.value.principal_name], 0)
        ].user_id
      : data.aws_identitystore_user.assign_user[each.value.principal_name].user_id
    )
}