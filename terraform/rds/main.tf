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
# RDS
# ------------------------------------------------------------------------------

resource "aws_db_instance" "this" {
  # Identity
  identifier = "${var.name}"

  # Engine
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  port           = var.port

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id
  iops                  = var.iops

  # Credentials
  db_name  = var.database_name
  username = var.username
  password                       = var.manage_master_user_password ? null : var.password
  manage_master_user_password    = var.manage_master_user_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = false

  # Backup & Maintenance
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  delete_automated_backups  = var.delete_automated_backups
  apply_immediately         = var.apply_immediately
  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade

  # HA
  multi_az = var.multi_az
  deletion_protection    = var.deletion_protection

  # Logs
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Enhanced Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period

  # Destroy snapshot
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : var.final_snapshot_identifier

  tags = merge(
    {
      Name        = "${var.environment}-${var.name}"
      Environment = var.environment
      Terraform   = "true"
    },
    var.tags
  )
}

# ------------------------------------------------------------------------------
# SUBNET GROUP NAME
# ------------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.db_subnet_ids
  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}