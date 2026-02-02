variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
}

variable "username_attributes" {
  description = "List of attributes Cognito users can sign in with (e.g., email, phone_number)"
  type        = list(string)
}

variable "minimum_length" {
  description = "Minimum length of the password"
  type        = number
  default     = 8
}

variable "require_lowercase" {
  description = "Whether password requires at least one lowercase letter"
  type        = bool
  default     = true
}

variable "require_numbers" {
  description = "Whether password requires at least one number"
  type        = bool
  default     = true
}

variable "require_symbols" {
  description = "Whether password requires at least one symbol"
  type        = bool
  default     = true
}

variable "require_uppercase" {
  description = "Whether password requires at least one uppercase letter"
  type        = bool
  default     = true
}

variable "recovery_mechanisms" {
  description = "List of recovery mechanisms for account recovery (e.g., name, priority)"
  type = list(object({
    name     = string
    priority = number
  }))
  default = []
}

variable "email_configuration" {
  description = "Configuration for Cognito/SES email sender"
  type = object({
    configuration_set     = optional(string)
    email_sending_account = string
    source_arn            = string
  })
  default = null
}

variable "verification_message_template" {
  description = "Template for verification messages"
  type = object({
    default_email_option  = optional(string)
    email_subject         = optional(string)
    email_message         = optional(string)
    email_subject_by_link = optional(string)
    email_message_by_link = optional(string)
    sms_message           = optional(string)
  })
  default = null
}

variable "admin_create_user_config" {
  description = "Admin create user configuration"
  type = object({
    allow_admin_create_user_only = bool
    invite_message_template = optional(object({
      email_subject = optional(string)
      email_message = optional(string)
      sms_message   = optional(string)
    }))
  })
  default = null
}

variable "schemas" {
  description = "Schema attributes for the Cognito user pool"
  type = list(object({
    name                = string
    required            = bool
    mutable             = bool
    attribute_data_type = string
    string_min_length   = optional(number)
    string_max_length   = optional(number)
  }))
  default = []
}

variable "custom_email_sender_lambda_arn" {
  description = "ARN of custom Lambda function for email sending"
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "KMS Key ARN for custom email sender"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the Cognito User Pool"
  type        = map(string)
  default     = {}
}

variable "provider_type" {
  description = "Provider type (use 'OIDC' to create the identity provider)"
  type        = string
  default     = null
}

variable "provider_name" {
  description = "Display name for the IdP (e.g., 'google')"
  type        = string
  default     = null
}

variable "oidc_issuer" {
  description = "OIDC issuer URL"
  type        = string
  default     = null
}

variable "authorize_scopes" {
  description = "OIDC authorize scopes"
  type        = string
  default     = null
}

variable "attributes_request_method" {
  description = "HTTP method for attributes request (GET/POST)"
  type        = string
  default     = null
}

variable "client_id" {
  description = "OIDC client ID"
  type        = string
  default     = null
}

variable "client_secret" {
  description = "OIDC client secret"
  type        = string
  default     = null
}

variable "jwks_uri" {
  description = "JWKS URI"
  type        = string
  default     = null
}

variable "authorize_url" {
  description = "OIDC authorize URL"
  type        = string
  default     = null
}

variable "token_url" {
  description = "OIDC token URL"
  type        = string
  default     = null
}

variable "attributes_url" {
  description = "OIDC user info / attributes URL"
  type        = string
  default     = null
}

variable "attributes_url_add_attributes" {
  description = "Whether to add OAuth attributes to the attributes URL (string true/false as required by AWS)"
  type        = string
  default     = null
}

variable "attribute_mapping" {
  description = "Cognito attribute mapping from IdP claims"
  type        = map(string)
  default     = {}
}

# ------------------------------
# User Pool Client
# ------------------------------
variable "user_pool_client_name" {
  description = "Cognito User Pool Client name"
  type        = string
}

variable "generate_secret" {
  description = "Whether to generate a client secret"
  type        = bool
  default     = false
}

variable "prevent_user_existence_errors" {
  description = "Enable user existence error prevention"
  type        = string
  default     = "ENABLED"
}

variable "enable_token_revocation" {
  description = "Enable token revocation"
  type        = bool
  default     = true
}

variable "enable_propagate_additional_user_context_data" {
  description = "Propagate additional user context data"
  type        = bool
  default     = false
}

variable "access_token_validity" {
  description = "Access token validity value"
  type        = number
  default     = 60
}

variable "id_token_validity" {
  description = "ID token validity value"
  type        = number
  default     = 60
}

variable "refresh_token_validity" {
  description = "Refresh token validity value"
  type        = number
  default     = 30
}

variable "token_units_access" {
  description = "Unit for access token validity (seconds|minutes|hours|days)"
  type        = string
  default     = "minutes"
}

variable "token_units_id" {
  description = "Unit for ID token validity (seconds|minutes|hours|days)"
  type        = string
  default     = "minutes"
}

variable "token_units_refresh" {
  description = "Unit for refresh token validity (seconds|minutes|hours|days)"
  type        = string
  default     = "days"
}

variable "explicit_auth_flows" {
  description = "Allowed explicit auth flows"
  type        = list(string)
  default     = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]
}

variable "supported_identity_providers" {
  description = "List of supported IdPs for the client (e.g., [\"COGNITO\", \"google\"])"
  type        = list(string)
  default     = ["COGNITO"]
}

variable "allowed_oauth_flows_user_pool_client" {
  description = "Enable OAuth flows on user pool client"
  type        = bool
  default     = true
}

variable "allowed_oauth_flows" {
  description = "Allowed OAuth flows (e.g., code, implicit, client_credentials)"
  type        = list(string)
  default     = ["code"]
}

variable "allowed_oauth_scopes" {
  description = "Allowed OAuth scopes"
  type        = list(string)
  default     = ["openid", "email", "profile"]
}

variable "callback_urls" {
  description = "OAuth callback URLs"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "OAuth logout URLs"
  type        = list(string)
  default     = []
}

variable "read_attributes" {
  description = "Client-readable user attributes"
  type        = list(string)
  default     = ["email", "email_verified"]
}

variable "write_attributes" {
  description = "Client-writable user attributes"
  type        = list(string)
  default     = ["email"]
}

# ------------------------------
# Cognito Groups
# ------------------------------
variable "cognito_groups" {
  description = "Map of Cognito groups to create"
  type = map(object({
    description = string
    precedence  = optional(number)
    role_arn    = optional(string)
  }))
  default = {}
}

variable "email_sending_account" {
  type        = string
  default     = "COGNITO_DEFAULT"
}

variable "pre_auth_lambda_arn" {
  description = "ARN of the pre-authentication Lambda trigger"
  type        = string
  default     = null
}

variable "post_auth_lambda_arn" {
  description = "ARN of the post-authentication Lambda trigger"
  type        = string
  default     = null
}