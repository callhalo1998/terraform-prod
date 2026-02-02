variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "force_delete" {
  description = "Whether to force delete the repository and all images"
  type        = bool
  default     = false
}

variable "encryption_type" {
  description = "The encryption type to use (AES256 or KMS)"
  type        = string
  default     = "AES256"
}

variable "environment" {
  description = "Deployment environment name (e.g., dev, prod)"
  type        = string
}

variable "lifecycle_policy" {
  description = "ECR lifecycle policy in JSON format"
  type        = string
}

variable "scan_on_push" {
  description = "ECR lifecycle policy in JSON format"
  type        = bool
  default     = true
}

variable "scan_type" {
  type    = string
  default = null
}

variable "scan_rules" {
  type    = list(object({
    scan_frequency = string
    filter         = string
  }))
  default = []
}