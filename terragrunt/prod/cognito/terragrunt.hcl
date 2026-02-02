terraform {
  source = "../../../terraform/cognito"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "secret" {
  config_path = "../secret-manager"
}

inputs = {
  environment         = "prod"
  user_pool_name      = "prod-"
  username_attributes = ["email"]

  minimum_length    = 8
  require_lowercase = true
  require_numbers   = true
  require_symbols   = true
  require_uppercase = true

  email_configuration = {
    configuration_set     = "my-first-configuration-set"
    email_sending_account = "DEVELOPER"
    source_arn            = "arn:aws:ses:eu-west-3::identity/devops@.fr"
  }

  recovery_mechanisms = [
    { 
        name = "verified_email",        
        priority = 1 
    },
    { 
        name = "verified_phone_number", 
        priority = 2 
    }
  ]

  schemas = [
    {
      name                = "email"
      required            = true
      mutable             = true
      attribute_data_type = "String"
      string_min_length   = 1
      string_max_length   = 256
    },
    {
      name                = "given_name"
      required            = false
      mutable             = true
      attribute_data_type = "String"
      string_min_length   = 1
      string_max_length   = 256
    },
    {
      name                = "family_name"
      required            = false
      mutable             = true
      attribute_data_type = "String"
      string_min_length   = 1
      string_max_length   = 256
    },
    {
      name                = "role"
      required            = false
      mutable             = true
      attribute_data_type = "String"
      string_min_length   = 1
      string_max_length   = 50
    },
    {
      name                = "is_synced"
      required            = false
      mutable             = true
      attribute_data_type = "String"
      string_min_length   = 1
      string_max_length   = 50
    },
    {
      name                = "sso_consent_agreed"
      required            = false
      mutable             = true
      attribute_data_type = "String"
    },
    {
      name                = "password_changed"
      required            = false
      mutable             = true
      attribute_data_type = "String"
    },
    {
      name                = "permission"
      required            = false
      mutable             = true
      attribute_data_type = "String"
    },
    {
      name                = "is_deleted"
      required            = false
      mutable             = true
      attribute_data_type = "String"
      string_min_length   = 1
      string_max_length   = 50
    }
  ]

  user_pool_client_name = "prod-web-client"

  # Client settings
  generate_secret                               = false
  prevent_user_existence_errors                 = "ENABLED"
  enable_token_revocation                       = true
  enable_propagate_additional_user_context_data = false

  # Token validity
  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30
  token_units_access     = "minutes"
  token_units_id         = "minutes"
  token_units_refresh    = "days"

  # Explicit auth flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Lambda Extensions
  custom_email_sender_lambda_arn = "arn:aws:lambda:eu-west-3::function:prod-lambda-email-sender"
  kms_key_arn                    = "arn:aws:kms:eu-west-3::key/e8b03cfb-ff57-4d02-a823-b3200331cf72"
  pre_auth_lambda_arn            = "arn:aws:lambda:eu-west-3::function:prod-lambda-pre-auth"
  post_auth_lambda_arn           = "arn:aws:lambda:eu-west-3::function:prod-lambda-post-auth"

  # Identity providers
  supported_identity_providers = ["COGNITO", "Google"]

  # OAuth 2.0
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]
  callback_urls                        = ["https://www..io/auth/login"]
  logout_urls                          = ["https://www..io"]

  # Google OIDC
  provider_name = "Google"
  provider_type = "Google"
  client_id     = dependency.secret.outputs.secret_values["prod-backend-secrets"]["GOOGLE_CLIENT_ID"]
  client_secret = dependency.secret.outputs.secret_values["prod-backend-secrets"]["GOOGLE_CLIENT_SECRET"]
  authorize_scopes = "email profile openid"
  attribute_mapping = {
    email       = "email"
    given_name  = "given_name"
    family_name = "family_name"
    username    = "sub"
  }

  # Attributes
  read_attributes = [
    "name",
    "email",
    "email_verified",
    "given_name",
    "family_name",
    "custom:role",
    "custom:is_synced",
    "custom:sso_consent_agreed",
    "custom:password_changed",
    "custom:is_deleted",
    "phone_number",
    "phone_number_verified"
  ]
  write_attributes = [
    "name",
    "email",
    "given_name",
    "family_name",
    "custom:role",
    "custom:is_synced",
    "custom:sso_consent_agreed",
    "custom:password_changed"
  ]

  cognito_groups = {
    admin = {
      description = "Administrator group"
      precedence  = 1
    }
    hrbp = {
      description = "HR Business Partner group"
      precedence  = 2
    }
    customer = {
      description = "Customer group"
      precedence  = 3
    }
  }
}