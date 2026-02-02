variable "ami_id" {
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  type        = string
  default     = null
}

variable "name" {
  type        = string
  default     = null
}

variable "security_group_ids" {
  type        = list(string)
}

variable "instance_type" {
  type        = string
}

variable "subnet_id" {
  type        = string
}

variable "key_name" {
  type        = string
  default     = null
}

variable "create_iam_role" {
  type        = bool
  default     = false
}

variable "user_data" {
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  type        = bool
  default     = false
}

variable "enable_detailed_monitoring" {
  type        = bool
  default     = false
}

variable "ebs_optimized" {
  type        = bool
  default     = false
}

variable "environment" {
  type        = string
  default     = "dev"
}

variable "root_volume_type" {
  type        = string
  default     = "gp3"
}

variable "root_volume_size_gb" {
  type        = number
  default     = 20
}

variable "root_volume_iops" {
  type        = number
  default     = null
}

variable "root_volume_throughput" {
  type        = number
  default     = null
}

variable "kms_key_id" {
  type        = string
  default     = null
}

variable "data_volumes" {
  description = <<EOT
Danh sách EBS phụ. Mỗi phần tử:
{
  device_name = "/dev/sdX"
  size_gb     = number
  volume_type = optional(string, "gp3")
  iops        = optional(number)
  throughput  = optional(number)
  kms_key_id  = optional(string)
}
EOT
  type = list(object({
    device_name = string
    size_gb     = number
    volume_type = optional(string)
    iops        = optional(number)
    throughput  = optional(number)
    kms_key_id  = optional(string)
  }))
  default = []
}

variable "source_dest_check" {
  type        = bool
  default     = true
}

variable "allocation_id" {
  type        = string
  default     = null
}