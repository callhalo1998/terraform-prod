variable "environment" {
  type = string
}

variable "name" {
  description = "RDS instance identifier"
  type        = string
}

# =========================
# Engine
# =========================
variable "engine" {
  type    = string
}

variable "engine_version" {
  type    = string
  default = null
}

variable "instance_class" {
  type = string
}

variable "port" {
  type    = number
  default = null
}

# =========================
# Storage
# =========================
variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 0 # 0 = tắt autoscaling
}

variable "storage_type" {
  type    = string
  default = "gp3"
}

variable "storage_encrypted" {
  type    = bool
  default = true
}

variable "kms_key_id" {
  type    = string
  default = null
}

variable "iops" {
  type    = number
  default = null
}

# =========================
# Credentials
# =========================
variable "database_name" {
  type    = string
  default = null # SQL Server bỏ qua
}

variable "username" {
  type      = string
  sensitive = true
}

variable "password" {
  type      = string
  sensitive = true
  default   = null
}

# =========================
# Network
# =========================

variable "vpc_security_group_ids" {
  type = list(string)
}

# =========================
# Backup & Maintenance
# =========================
variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "backup_window" {
  type    = string
  default = null
}

variable "maintenance_window" {
  type    = string
  default = null
}

variable "copy_tags_to_snapshot" {
  type    = bool
  default = true
}

variable "delete_automated_backups" {
  type    = bool
  default = true
}

variable "apply_immediately" {
  type    = bool
  default = false
}

variable "allow_major_version_upgrade" {
  type    = bool
  default = false
}

variable "auto_minor_version_upgrade" {
  type    = bool
  default = true
}

# =========================
# High Availability
# =========================
variable "multi_az" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

# =========================
# Logs
# =========================
variable "enabled_cloudwatch_logs_exports" {
  type    = list(string)
  default = []
}

# =========================
# Enhanced Monitoring
# =========================
variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds"
  type        = number
  default     = 0
  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "monitoring_role_arn" {
  type    = string
  default = null
}

# =========================
# Performance Insights
# =========================
variable "performance_insights_enabled" {
  type    = bool
  default = false
}

variable "performance_insights_retention_period" {
  type    = number
  default = 7
}

# =========================
# Final snapshot
# =========================
variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "final_snapshot_identifier" {
  type    = string
  default = null
}

# =========================
# Tags
# =========================
variable "tags" {
  type    = map(string)
  default = {}
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "manage_master_user_password" {
  type    = bool
  default = false
}