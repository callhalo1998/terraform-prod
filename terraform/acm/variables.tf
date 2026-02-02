variable "domain_name" {
  description = "The primary domain name for the ACM certificate"
  type        = string
}

variable "validation_method" {
  description = "Method to validate the ACM certificate (DNS or EMAIL)"
  type        = string
  default     = "DNS"
}

variable "subject_alternative_names" {
  description = "A list of additional FQDNs to include in the certificate"
  type        = list(string)
  default     = []
}

variable "key_algorithm" {
  description = "Specifies the algorithm of the public and private key pair"
  type        = string
  default     = "RSA_2048"
}

variable "tags" {
  description = "Tags to apply to the ACM certificate"
  type        = map(string)
  default     = {}
}
