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
# Cognito User Pool
# ------------------------------------------------------------------------------

resource "aws_cognito_user_pool" "this" {
  name                = "${var.user_pool_name}"
  mfa_configuration   = "OPTIONAL"
  username_attributes = var.username_attributes
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  software_token_mfa_configuration {
    enabled = true
  }

  email_configuration {
    email_sending_account = var.email_sending_account # "COGNITO_DEFAULT" or "DEVELOPER"
  }

  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }

  password_policy {
    minimum_length    = var.minimum_length
    require_lowercase = var.require_lowercase
    require_numbers   = var.require_numbers
    require_symbols   = var.require_symbols
    require_uppercase = var.require_uppercase
  }
  
  account_recovery_setting {
    dynamic "recovery_mechanism" {
      for_each = try(var.recovery_mechanisms, [])
      content {
        name     = recovery_mechanism.value.name
        priority = recovery_mechanism.value.priority
      }
    }
  }

# ------------------------------------------------------------------------------  
# Cognito with SES or built-in Cognito sender
# ------------------------------------------------------------------------------

  #--- for Cognito/SES sender ---# 
  dynamic "email_configuration" {
    for_each = (var.custom_email_sender_lambda_arn == null && var.email_configuration != null) ? [var.email_configuration] : []
    content {
        configuration_set     = lookup(email_configuration.value, "configuration_set", null)
        email_sending_account = email_configuration.value.email_sending_account
        source_arn            = email_configuration.value.source_arn
    }
  }

  #--- for Cognito/SES sender ---#
  dynamic "verification_message_template" {
    for_each = var.verification_message_template == null ? [] : [var.verification_message_template]
    content {
        default_email_option   = lookup(verification_message_template.value, "default_email_option", null)
        email_subject          = lookup(verification_message_template.value, "email_subject", null)
        email_message          = lookup(verification_message_template.value, "email_message", null)
        email_subject_by_link  = lookup(verification_message_template.value, "email_subject_by_link", null)
        email_message_by_link  = lookup(verification_message_template.value, "email_message_by_link", null)
        sms_message            = lookup(verification_message_template.value, "sms_message", null)
    }
  }

  #--- for Cognito/SES sender ---#
  dynamic "admin_create_user_config" {
    for_each = var.admin_create_user_config == null ? [] : [var.admin_create_user_config]
    content {
        allow_admin_create_user_only = admin_create_user_config.value.allow_admin_create_user_only

        dynamic "invite_message_template" {
            for_each = try([admin_create_user_config.value.invite_message_template], [])
            content {
                email_subject = lookup(invite_message_template.value, "email_subject", null)
                email_message = lookup(invite_message_template.value, "email_message", null)
                sms_message   = lookup(invite_message_template.value, "sms_message", null)
            }
        }
    }
  }
  

# ------------------------------------------------------------------------------  
# Schema & Lambda custom email sender
# ------------------------------------------------------------------------------

  dynamic "schema" {
    for_each = var.schemas
    content {
        name                     = schema.value.name
        required                 = schema.value.required
        mutable                  = schema.value.mutable
        attribute_data_type      = schema.value.attribute_data_type
        developer_only_attribute = false

        dynamic "string_attribute_constraints" {
        for_each = schema.value.attribute_data_type == "String" ? [1] : []
        content {
            min_length = try(schema.value.string_min_length, 1)
            max_length = try(schema.value.string_max_length, 256)
        }
        }
    }
  }

  dynamic "lambda_config" {
    for_each = var.custom_email_sender_lambda_arn != null ? [1] : []
    content {
      pre_authentication  = var.pre_auth_lambda_arn
      post_authentication = var.post_auth_lambda_arn
      custom_email_sender {
        lambda_arn    = var.custom_email_sender_lambda_arn
        lambda_version = "V1_0"
      }
      kms_key_id = var.kms_key_arn
    }
  }

  tags = var.tags
}

# ------------------------------------------------------------------------------
# GOOGLE (built-in provider)
# ------------------------------------------------------------------------------
resource "aws_cognito_identity_provider" "google" {
  count         = var.provider_type == "Google" && var.client_id != null && var.client_secret != null ? 1 : 0
  user_pool_id  = aws_cognito_user_pool.this.id
  provider_name = coalesce(var.provider_name, "Google")
  provider_type = "Google"

  provider_details = {
    client_id        = var.client_id
    client_secret    = var.client_secret
    authorize_scopes = coalesce(var.authorize_scopes, "email profile openid")
  }

  attribute_mapping = var.attribute_mapping
}

# ------------------------------------------------------------------------------
# OIDC (Google OIDC or other IdP OIDC)
# ------------------------------------------------------------------------------
resource "aws_cognito_identity_provider" "oidc" {
  count         = var.provider_type == "OIDC" && var.oidc_issuer != null ? 1 : 0
  user_pool_id  = aws_cognito_user_pool.this.id
  provider_name = coalesce(var.provider_name, "google")
  provider_type = "OIDC"

  provider_details = merge(
    {
      oidc_issuer              = var.oidc_issuer
      authorize_scopes         = coalesce(var.authorize_scopes, "email profile openid")
      attributes_request_method = coalesce(var.attributes_request_method, "GET")
    },
    var.client_id  != null ? { client_id  = var.client_id }  : {},
    var.client_secret != null ? { client_secret = var.client_secret } : {},
    var.jwks_uri    != null ? { jwks_uri   = var.jwks_uri }   : {},
    var.authorize_url != null ? { authorize_url = var.authorize_url } : {},
    var.token_url     != null ? { token_url     = var.token_url }     : {},
    var.attributes_url != null ? { attributes_url = var.attributes_url } : {},
    var.attributes_url_add_attributes != null ? { attributes_url_add_attributes = var.attributes_url_add_attributes } : {}
  )

  attribute_mapping = var.attribute_mapping
}

# ------------------------------------------------------------------------------  
# Cognito User Pool Client
# ------------------------------------------------------------------------------

resource "aws_cognito_user_pool_client" "this" {
  name         = var.user_pool_client_name
  user_pool_id = aws_cognito_user_pool.this.id

  # Client settings
  generate_secret                               = var.generate_secret
  prevent_user_existence_errors                 = var.prevent_user_existence_errors
  enable_token_revocation                       = var.enable_token_revocation
  enable_propagate_additional_user_context_data = var.enable_propagate_additional_user_context_data

  # Token validity
  access_token_validity  = var.access_token_validity
  id_token_validity      = var.id_token_validity
  refresh_token_validity = var.refresh_token_validity
  token_validity_units {
    access_token  = var.token_units_access
    id_token      = var.token_units_id
    refresh_token = var.token_units_refresh
  }

  # Explicit auth flows
  explicit_auth_flows = var.explicit_auth_flows

  # Supported identity providers
  supported_identity_providers = var.supported_identity_providers

  # OAuth 2.0
  allowed_oauth_flows_user_pool_client = var.allowed_oauth_flows_user_pool_client
  allowed_oauth_flows                  = var.allowed_oauth_flows
  allowed_oauth_scopes                 = var.allowed_oauth_scopes
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls

  # Attributes
  read_attributes  = var.read_attributes
  write_attributes = var.write_attributes
}

# ------------------------------------------------------------------------------  
# Cognito User Pool Domain
# ------------------------------------------------------------------------------

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${random_string.domain_suffix.result}"
  user_pool_id = aws_cognito_user_pool.this.id
}

resource "random_string" "domain_suffix" {
  length  = 8
  special = false
  upper   = false
}

# ------------------------------------------------------------------------------  
# Cognito Groups of Users
# ------------------------------------------------------------------------------

resource "aws_cognito_user_group" "this" {
  for_each     = var.cognito_groups
  name         = each.key
  user_pool_id = aws_cognito_user_pool.this.id
  description  = each.value.description
  precedence   = try(each.value.precedence, null)
  role_arn     = try(each.value.role_arn, null)
}