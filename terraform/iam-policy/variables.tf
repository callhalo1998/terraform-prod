variable "policy_name" {
  type        = string
  description = "Unique name of the customer-managed IAM policy."
}

variable "policy_path" {
  type        = string
  default     = "/"
  description = "Policy path (keep '/' unless you need namespacing)."
}

variable "description" {
  type        = string
  default     = null
  description = "Optional policy description."
}

variable "policy_document_json" {
  type        = string
  description = "JSON string of the policy document."
}

variable "tags" {
  type        = map(string)
  default     = {}
}