# AWS RDS Aurora PostgreSQL Cluster for Grahvani
# Multi-AZ deployment with automated backups, encryption, and pgvector extension.

resource "aws_rds_cluster" "grahvani" {
  cluster_identifier      = "grahvani-db-cluster"
  engine                 = "aurora-postgresql"
  engine_version         = "16.2"
  engine_mode            = "provisioned"
  database_name          = "grahvani"
  master_username        = var.db_master_username
  master_password        = var.db_master_password
  enable_http_endpoint   = true  # For Data API access
  skip_final_snapshot    = false
  final_snapshot_identifier = "grahvani-db-final-snapshot"
  backup_retention_period = 35  # 35 days of automated backups
  preferred_backup_window = "17:00-19:00"  # UTC
  preferred_maintenance_window = "sun:20:00-sun:22:00"  # UTC
  
  # Multi-AZ deployment for high availability
  availability_zones = [
    "${var.aws_region}a",
    "${var.aws_region}b",
    "${var.aws_region}c",
  ]
  
  # Storage configuration
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn
  
  # Network isolation
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.grahvani.name
  
  # Enable pgvector extension
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  # Parameter group for pgvector
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.grahvani.name
  
  tags = {
    Name        = "grahvani-db-cluster"
    Environment = "production"
    Project     = "Grahvani"
  }
}

# RDS Cluster Instances (2 instances for Multi-AZ)
resource "aws_rds_cluster_instance" "grahvani" {
  count              = 2
  cluster_identifier = aws_rds_cluster.grahvani.id
  instance_class     = "db.r6g.large"  # 2 vCPU, 16 GiB RAM
  engine             = aws_rds_cluster.grahvani.engine
  engine_version     = aws_rds_cluster.grahvani.engine_version
  
  # Performance Insights for monitoring
  performance_insights_enabled = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  
  tags = {
    Name = "grahvani-db-instance-${count.index}"
  }
}

# Parameter group for pgvector extension
resource "aws_rds_cluster_parameter_group" "grahvani" {
  name        = "grahvani-pgvector-params"
  family      = "aurora-postgresql16"
  description = "Parameter group for Grahvani with pgvector extension"
  
  parameter {
    name  = "shared_preload_libraries"
    value = "vector"
  }
  
  parameter {
    name  = "search_path"
    value = "$user,public,extensions"
  }
  
  parameter {
    name  = "max_locks_per_transaction"
    value = "128"
  }
  
  parameter {
    name  = "autovacuum_vacuum_scale_factor"
    value = "0.05"
  }
  
  parameter {
    name  = "autovacuum_analyze_scale_factor"
    value = "0.02"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "grahvani" {
  name       = "grahvani-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
    aws_subnet.private_c.id,
  ]
  
  tags = {
    Name = "grahvani-db-subnet-group"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "grahvani-rds-sg"
  description = "Security group for Grahvani RDS cluster"
  vpc_id      = aws_vpc.main.id
  
  # Allow inbound PostgreSQL from App Runner
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_apprunner_service.grahvani_api.security_groups[0]]
  }
  
  # Allow inbound PostgreSQL from bastion (for migrations)
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "grahvani-rds-sg"
  }
}

# KMS Key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for Grahvani RDS encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Name = "grahvani-rds-kms-key"
  }
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "grahvani-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alarm when RDS CPU exceeds 80% for 5 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.grahvani.id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_memory" {
  alarm_name          = "grahvani-rds-low-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1073741824"  # 1 GiB
  alarm_description   = "Alarm when RDS freeable memory drops below 1 GiB"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.grahvani.id
  }
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "grahvani-alerts"
  
  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 20
        numRetries         = 3
        numMaxDelayRetries = 0
        numNoDelayRetries  = 0
        numMinDelayRetries = 0
        backoffFunction    = "linear"
      }
      disableSubscriptionOverrides = false
    }
  })
  
  tags = {
    Name = "grahvani-alerts"
  }
}