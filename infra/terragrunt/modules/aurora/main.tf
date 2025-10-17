terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  global_enabled = var.global.enabled
  is_primary     = var.global.is_primary
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-subnets"
  })
}

resource "aws_security_group" "this" {
  name        = "${var.name}-aurora"
  description = "Aurora access for ${var.name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [true] : []
    content {
      from_port   = var.port
      to_port     = var.port
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_security_group_ids) > 0 ? [true] : []
    content {
      from_port       = var.port
      to_port         = var.port
      protocol        = "tcp"
      security_groups = var.allowed_security_group_ids
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-aurora"
  })
}

resource "aws_rds_cluster_parameter_group" "this" {
  name        = "${var.name}-cluster-params"
  family      = var.parameter_family
  description = "Aurora cluster parameters for ${var.name}"

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-cluster-params"
  })
}

resource "aws_rds_parameter_group" "instance" {
  name        = "${var.name}-instance-params"
  family      = var.parameter_family
  description = "Aurora instance parameters for ${var.name}"

  dynamic "parameter" {
    for_each = var.instance_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-instance-params"
  })
}

resource "aws_rds_global_cluster" "this" {
  count = local.global_enabled && local.is_primary ? 1 : 0

  global_cluster_identifier = var.global.global_cluster_identifier
  engine                    = var.engine
  engine_version            = var.engine_version
  database_name             = var.database_name
}

resource "aws_rds_cluster" "this" {
  cluster_identifier              = "${var.name}-cluster"
  engine                          = var.engine
  engine_version                  = var.engine_version
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.master_password
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = concat([aws_security_group.this.id], var.additional_security_group_ids)
  port                            = var.port
  kms_key_id                      = var.kms_key_id
  storage_encrypted               = true
  skip_final_snapshot             = var.skip_final_snapshot
  apply_immediately               = var.apply_immediately
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  deletion_protection             = var.deletion_protection
  backup_retention_period         = var.backup_retention_period
  copy_tags_to_snapshot           = true
  global_cluster_identifier       = local.global_enabled ? var.global.global_cluster_identifier : null
  source_region                   = local.global_enabled && !local.is_primary ? var.global.primary_region : null
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.serverlessv2_scaling_configuration == null ? [] : [var.serverlessv2_scaling_configuration]
    content {
      min_capacity = serverlessv2_scaling_configuration.value.min_capacity
      max_capacity = serverlessv2_scaling_configuration.value.max_capacity
    }
  }

  lifecycle {
    ignore_changes = [ master_password ]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-cluster"
  })
}

resource "aws_rds_cluster_instance" "this" {
  count              = var.instance_count
  identifier         = "${var.name}-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = var.engine
  engine_version     = var.engine_version
  apply_immediately  = var.apply_immediately
  db_parameter_group_name = aws_rds_parameter_group.instance.name

  auto_minor_version_upgrade = true

  tags = merge(var.tags, {
    Name = "${var.name}-${count.index}"
  })
}

output "cluster_id" {
  value = aws_rds_cluster.this.id
}

output "cluster_endpoint" {
  value = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  value = aws_rds_cluster.this.reader_endpoint
}

output "security_group_id" {
  value = aws_security_group.this.id
}

output "subnet_group_name" {
  value = aws_db_subnet_group.this.name
}
