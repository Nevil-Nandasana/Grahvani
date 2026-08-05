# AWS App Runner Service for Grahvani API
# Manages the FastAPI container deployment with auto-scaling and health checks.

resource "aws_apprunner_service" "grahvani_api" {
  service_name = "grahvani-api"
  
  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_service_role.arn
    }
    
    image_repository {
      image_identifier      = "${aws_ecr_repository.grahvani.repository_url}:latest"
      image_repository_type = "ECR"
      image_configuration {
        port = "8000"
        runtime_environment_variables = {
          "APP_ENV"                = "production"
          "DATABASE_URL"           = aws_rds_cluster.grahvani.endpoint
          "REDIS_URL"              = aws_elasticache_cluster.grahvani.cache_nodes[0].address
          "GEMINI_API_KEY"         = var.gemini_api_key
          "RAZORPAY_KEY_ID"        = var.razorpay_key_id
          "RAZORPAY_KEY_SECRET"    = var.razorpay_key_secret
          "RAZORPAY_WEBHOOK_SECRET" = var.razorpay_webhook_secret
        }
      }
    }
  }
  
  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration.grahvani.arn
  
  health_check_configuration {
    healthy_threshold   = 1
    unhealthy_threshold = 5
    interval            = 10
    path                = "/health"
    protocol            = "HTTP"
    timeout             = 5
  }
  
  tags = {
    Name        = "grahvani-api"
    Environment = "production"
    Project     = "Grahvani"
  }
}

# Auto-scaling configuration for App Runner
resource "aws_apprunner_auto_scaling_configuration" "grahvani" {
  auto_scaling_configuration_name = "grahvani-api-scaling"
  
  max_concurrency = 100
  max_size        = 10
  min_size        = 2
  
  tags = {
    Name = "grahvani-api-scaling"
  }
}

# IAM Role for App Runner to access ECR
resource "aws_iam_role" "apprunner_service_role" {
  name = "grahvani-apprunner-service-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy attachment for ECR access
resource "aws_iam_role_policy_attachment" "apprunner_ecr_access" {
  role       = aws_iam_role.apprunner_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}