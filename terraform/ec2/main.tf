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

# --------------------------------------------------
# EC2 INSTANCE STANDALONE
# --------------------------------------------------

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name
  iam_instance_profile   = var.iam_instance_profile
  user_data                   = var.user_data
  user_data_replace_on_change = true
  source_dest_check      = var.source_dest_check

  associate_public_ip_address = var.associate_public_ip_address
  monitoring                  = var.enable_detailed_monitoring
  ebs_optimized               = var.ebs_optimized

  tags = {
    Name        = var.name
    Environment = var.environment
    Terraform   = "true"
  }

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size_gb
    delete_on_termination = true
    iops                  = try(var.root_volume_iops, null)
    throughput            = try(var.root_volume_throughput, null)
    encrypted             = true
    kms_key_id            = try(var.kms_key_id, null)
    tags = {
      Environment = var.environment
      Terraform   = "true"
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.data_volumes
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = try(ebs_block_device.value.volume_type, "gp3")
      volume_size           = ebs_block_device.value.size_gb
      iops                  = try(ebs_block_device.value.iops, null)
      throughput            = try(ebs_block_device.value.throughput, null)
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = try(ebs_block_device.value.kms_key_id, var.kms_key_id)
      tags = {
        Environment = var.environment
        Terraform   = "true"
      }
    }
  }
  lifecycle {
    ignore_changes = [ami]
  }
}

# --------------------------------------------------
# ATTACH EIP
# --------------------------------------------------

resource "aws_eip_association" "nat" {
  count         = var.allocation_id == null ? 0 : 1
  instance_id   = aws_instance.this.id
  allocation_id = var.allocation_id
}