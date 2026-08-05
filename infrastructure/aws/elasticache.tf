# AWS ElastiCache Redis Cluster for Grahvani
# Used for rate limiting, session cache, Celery/Dramatiq broker, and pub/sub.

resource "aws_elasticache_replication_group" "grahvani" {
  replication_group_id       = "grahvani-redis"
  replication_group_description = "Grahvani Redis cluster for caching and task queue"
  
  engine                    = "redis"
  engine_version            = "7.2"
  node_type                 = "cache.r6g.large"
  number_cache_clusters     = 2  # Primary + replica for Multi-AZ
  
  automatic_failover_enabled = true
  multi_az_enabled          = true
  
  # Security & Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                = var.redis_auth_token  # Stored in Secrets Manager
  
  # Network
  subnet_group_name         = aws_elasticache_subnet_group.grahvani.name
  security_group_ids        = [aws_security_group.elasticache.id]
  
  # Maintenance
  preferred_maintenance_window = "sun:03:00-sun:05:00"
  snapshot_retention_limit    = 7
  snapshot_window             = "07:00-09:00"
  
  # Logging
  log_delivery_configuration {
    destination_type = "cloudwatch-logs"
    destination_details {
      cloudwatch_logs {
        log_group = aws_cloudwatch_log_group.redis.name
      }
    }
    log_format = "json"
    log_type   = "slow-log"
  }
  
  log_delivery_configuration {
    destination_type = "cloudwatch-logs"
    destination_details {
      cloudwatch_logs {
        log_group = aws_cloudwatch_log_group.redis.name
      }
    }
    log_format = "json"
    log_type   = "engine-log"
  }
  
  tags = {
    Name        = "grahvani-redis"
    Environment = "production"
    Project     = "Grahvani"
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "grahvani" {
  name       = "grahvani-elasticache-subnet"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
    aws_subnet.private_c.id,
  ]
  
  tags = {
    Name = "grahvani-elasticache-subnet"
  }
}

# Security Group for ElastiCache
resource "aws_security_group" "elasticache" {
  name        = "grahvani-elasticache-sg"
  description = "Security group for Grahvani ElastiCache Redis"
  vpc_id      = aws_vpc.main.id
  
  # Allow Redis traffic from App Runner
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.apprunner.id]
  }
  
  # Allow Redis traffic from bastion
  ingress {
    from_port       = 6379
    to_port         = 6379
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
    Name = "grahvani-elasticache-sg"
  }
}

# CloudWatch Log Group for Redis
resource "aws_cloudwatch_log_group" "redis" {
  name              = "/aws/elasticache/grahvani-redis"
  retention_in_days = 30
  
  tags = {
    Name = "grahvani-redis-logs"
  }
}

# CloudWatch Alarms for Redis
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "grahvani-redis-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alarm when Redis CPU exceeds 80% for 5 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.grahvani.replication_group_id
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "grahvani-redis-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "Alarm when Redis memory usage exceeds 85%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.grahvani.replication_group_id
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_connections" {
  alarm_name          = "grahvani-redis-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "10000"
  alarm_description   = "Alarm when Redis connections exceed 10,000"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.grahvani.replication_group_id
  }
}