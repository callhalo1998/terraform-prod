terraform {
  source = "../../../../../terraform/rds"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "private_subnet" {
  config_path = "../../../vpc/private-subnet"
}

dependency "sg" {
  config_path = "../sg"
}

dependency "iam_enhanced_monitoring" {
  config_path = "../iam/enhanced_monitoring"
}

inputs = {
  # Engine  
  environment = "prod"
  name        = "prod--postgres"
  engine         = "postgres"
  engine_version = "17.5"
  instance_class = "db.t4g.small"
  port           = 5432

  # Storage
  allocated_storage      = 200
  max_allocated_storage  = 0
  storage_type           = "gp3"
  storage_encrypted      = true

  # Credentials
  database_name               = "prod_"
  username                    = "prod_"
  manage_master_user_password = true

  # Network
  db_subnet_ids          = [
    dependency.private_subnet.outputs.private_subnet_ids["prod-database-subnet-1"],
    dependency.private_subnet.outputs.private_subnet_ids["prod-database-subnet-2"]
  ]

  vpc_security_group_ids = [dependency.sg.outputs.security_group_ids["prod-postgresql-sg"]]
  publicly_accessible    = false

  # Backup & Maintenance
  backup_retention_period     = 14
  backup_window               = "03:00-04:00"
  maintenance_window          = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot       = true
  delete_automated_backups    = true
  apply_immediately           = true
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  # HA
  multi_az            = true
  deletion_protection = true
  # Logs
  enabled_cloudwatch_logs_exports = ["postgresql"]
  # Enhanced Monitoring
  monitoring_interval = 30
  monitoring_role_arn = dependency.iam_enhanced_monitoring.outputs.role_arn
  performance_insights_enabled = true
  skip_final_snapshot = true
}