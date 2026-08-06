# AWS App Runner Services for Grahvani
# Two services:
#   1. grahvani-api   — FastAPI HTTP server (port 8000)
#   2. grahvani-worker — Dramatiq background task worker (no public port)
#
# Both services connect to the private VPC for RDS and Redis access.
# All secrets are sourced from AWS Secrets Manager — never stored as plain env vars.

# ─── VPC Connector ───────────────────────────────────────────────────────────
# Required for App Runner to connect to private VPC resources (RDS, Redis).

resource "aws_apprunner_vpc_connector" "grahvani" {
  vpc_connector_name = "grahvani-vpc-connector"
  subnets = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
    aws_subnet.private_c.id,
  ]
  security_groups = [aws_security_group.apprunner.id]

  tags = {
    Name = "grahvani-vpc-connector"
  }
}

# ─── App Runner Service: API ──────────────────────────────────────────────────

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

        # Non-sensitive runtime configuration only.
        # All secrets come from runtime_environment_secrets below.
        runtime_environment_variables = {
          APP_ENV              = "production"
          AWS_REGION           = var.aws_region
          LOG_LEVEL            = "INFO"
          DEBUG                = "false"
          AWS_S3_CURATED_BUCKET = "${var.aws_s3_bucket_prefix}-curated-sources"
          AWS_S3_PDF_BUCKET     = "${var.aws_s3_bucket_prefix}-pdf-exports"
        }

        # Secrets are fetched from Secrets Manager at container startup.
        # Format: "ENV_VAR_NAME" = "<secret_arn>:<json_key>::"
        # For plain-string secrets omit the JSON key: "<secret_arn>:::"
        runtime_environment_secrets = {
          # Database — JSON secret with host/port/user/password/dbname
          DB_SECRET_ARN = aws_secretsmanager_secret.db_credentials.arn

          # Redis auth token (plain string)
          REDIS_AUTH_TOKEN = "${aws_secretsmanager_secret.redis_auth.arn}:::"

          # Google Gemini API key (plain string)
          GEMINI_API_KEY = "${aws_secretsmanager_secret.gemini_api_key.arn}:::"

          # Razorpay credentials JSON
          RAZORPAY_SECRET_ARN = aws_secretsmanager_secret.razorpay.arn

          # Apple App Store JSON
          APPLE_SECRET_ARN = aws_secretsmanager_secret.apple_app_store.arn

          # Firebase service account JSON
          FIREBASE_SECRET_ARN = aws_secretsmanager_secret.firebase.arn

          # App secret key (plain string)
          APP_SECRET_KEY = "${aws_secretsmanager_secret.app_secret.arn}:::"

          # Google Places API key (plain string)
          GOOGLE_PLACES_API_KEY = "${aws_secretsmanager_secret.google_places.arn}:::"

          # Langfuse observability
          LANGFUSE_SECRET_KEY = "${aws_secretsmanager_secret.langfuse.arn}:secret_key::"
          LANGFUSE_PUBLIC_KEY = "${aws_secretsmanager_secret.langfuse.arn}:public_key::"
          LANGFUSE_HOST       = "${aws_secretsmanager_secret.langfuse.arn}:host::"
        }
      }
    }
  }

  # Auto-scaling: scale from 2 to 10 instances, max 100 concurrent requests per instance.
  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration.grahvani.arn

  # Health check via /health endpoint.
  health_check_configuration {
    healthy_threshold   = 1
    unhealthy_threshold = 5
    interval            = 10
    path                = "/health"
    protocol            = "HTTP"
    timeout             = 5
  }

  # VPC connectivity — required to reach RDS and Redis.
  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.grahvani.arn
    }

    # Ingress is public (HTTPS via App Runner's managed load balancer).
    ingress_configuration {
      is_publicly_accessible = true
    }
  }

  # Instance configuration: 1 vCPU, 2 GiB RAM per instance.
  instance_configuration {
    cpu               = "1024"  # 1 vCPU
    memory            = "2048"  # 2 GiB
    instance_role_arn = aws_iam_role.apprunner_instance_role.arn
  }

  tags = {
    Name        = "grahvani-api"
    ServiceType = "api"
  }

  # Ensure the VPC connector, IAM roles, and secrets are ready first.
  depends_on = [
    aws_apprunner_vpc_connector.grahvani,
    aws_iam_role_policy_attachment.apprunner_ecr_access,
    aws_iam_role_policy_attachment.apprunner_s3_access,
    aws_iam_role_policy_attachment.apprunner_secretsmanager,
    aws_secretsmanager_secret_version.db_credentials,
    aws_secretsmanager_secret_version.gemini_api_key,
    aws_secretsmanager_secret_version.redis_auth,
    aws_secretsmanager_secret_version.razorpay,
    aws_secretsmanager_secret_version.app_secret,
  ]
}

# ─── App Runner Service: Dramatiq Worker ─────────────────────────────────────
# The worker uses the same ECR image but runs with a different CMD.
# App Runner workers don't expose a public HTTP port.

resource "aws_apprunner_service" "grahvani_worker" {
  service_name = "grahvani-worker"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_service_role.arn
    }

    image_repository {
      image_identifier      = "${aws_ecr_repository.grahvani.repository_url}:worker-latest"
      image_repository_type = "ECR"

      image_configuration {
        # Workers don't serve HTTP — use port 8080 as a dummy health check target.
        port = "8080"

        runtime_environment_variables = {
          APP_ENV   = "production"
          AWS_REGION = var.aws_region
          LOG_LEVEL = "INFO"
          DEBUG     = "false"
          AWS_S3_CURATED_BUCKET = "${var.aws_s3_bucket_prefix}-curated-sources"
          AWS_S3_PDF_BUCKET     = "${var.aws_s3_bucket_prefix}-pdf-exports"
        }

        runtime_environment_secrets = {
          DB_SECRET_ARN        = aws_secretsmanager_secret.db_credentials.arn
          REDIS_AUTH_TOKEN     = "${aws_secretsmanager_secret.redis_auth.arn}:::"
          GEMINI_API_KEY       = "${aws_secretsmanager_secret.gemini_api_key.arn}:::"
          RAZORPAY_SECRET_ARN  = aws_secretsmanager_secret.razorpay.arn
          FIREBASE_SECRET_ARN  = aws_secretsmanager_secret.firebase.arn
          APP_SECRET_KEY       = "${aws_secretsmanager_secret.app_secret.arn}:::"
          GOOGLE_PLACES_API_KEY = "${aws_secretsmanager_secret.google_places.arn}:::"
          LANGFUSE_SECRET_KEY  = "${aws_secretsmanager_secret.langfuse.arn}:secret_key::"
          LANGFUSE_PUBLIC_KEY  = "${aws_secretsmanager_secret.langfuse.arn}:public_key::"
          LANGFUSE_HOST        = "${aws_secretsmanager_secret.langfuse.arn}:host::"
        }
      }
    }
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration.grahvani_worker.arn

  # Worker health check (lightweight HTTP ping endpoint in the worker).
  health_check_configuration {
    healthy_threshold   = 1
    unhealthy_threshold = 5
    interval            = 20
    path                = "/health"
    protocol            = "HTTP"
    timeout             = 10
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.grahvani.arn
    }

    # Worker is not publicly accessible.
    ingress_configuration {
      is_publicly_accessible = false
    }
  }

  # Worker instance: 2 vCPU, 4 GiB RAM (heavier workloads — PDF gen, embeddings).
  instance_configuration {
    cpu               = "2048"  # 2 vCPU
    memory            = "4096"  # 4 GiB
    instance_role_arn = aws_iam_role.apprunner_instance_role.arn
  }

  tags = {
    Name        = "grahvani-worker"
    ServiceType = "worker"
  }

  depends_on = [
    aws_apprunner_vpc_connector.grahvani,
    aws_iam_role_policy_attachment.apprunner_ecr_access,
    aws_iam_role_policy_attachment.apprunner_s3_access,
    aws_iam_role_policy_attachment.apprunner_secretsmanager,
  ]
}

# ─── Auto-Scaling Configurations ─────────────────────────────────────────────

resource "aws_apprunner_auto_scaling_configuration" "grahvani" {
  auto_scaling_configuration_name = "grahvani-api-scaling"

  max_concurrency = 100  # Max concurrent requests per instance before scaling
  max_size        = 10   # Max number of instances
  min_size        = 2    # Min instances (keeps 2 warm for HA)

  tags = {
    Name = "grahvani-api-scaling"
  }
}

resource "aws_apprunner_auto_scaling_configuration" "grahvani_worker" {
  auto_scaling_configuration_name = "grahvani-worker-scaling"

  max_concurrency = 10   # Workers process fewer, heavier tasks
  max_size        = 5
  min_size        = 1    # One worker always running

  tags = {
    Name = "grahvani-worker-scaling"
  }
}

# ─── IAM Role: App Runner Service Role (ECR pull) ────────────────────────────
# This role is assumed by App Runner infrastructure (not the app code).
# Used exclusively to pull images from ECR.

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

  tags = {
    Name = "grahvani-apprunner-service-role"
  }
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_access" {
  role       = aws_iam_role.apprunner_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# ─── IAM Role: App Runner Instance Role (runtime permissions) ────────────────
# This role is assumed by the running application container.
# Grants access to S3, Secrets Manager, CloudWatch, and KMS.

resource "aws_iam_role" "apprunner_instance_role" {
  name = "grahvani-apprunner-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "grahvani-apprunner-instance-role"
  }
}

# Allow the instance role to write CloudWatch logs
resource "aws_iam_role_policy_attachment" "instance_cloudwatch" {
  role       = aws_iam_role.apprunner_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# Allow the instance role to use X-Ray tracing
resource "aws_iam_role_policy_attachment" "instance_xray" {
  role       = aws_iam_role.apprunner_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# ─── App Runner CloudWatch Log Group ─────────────────────────────────────────
resource "aws_cloudwatch_log_group" "apprunner_api" {
  name              = "/aws/apprunner/grahvani-api"
  retention_in_days = 30

  tags = {
    Name = "grahvani-apprunner-api-logs"
  }
}

resource "aws_cloudwatch_log_group" "apprunner_worker" {
  name              = "/aws/apprunner/grahvani-worker"
  retention_in_days = 30

  tags = {
    Name = "grahvani-apprunner-worker-logs"
  }
}

# ─── CloudWatch Alarm: App Runner Request Latency ─────────────────────────────
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "grahvani-api-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "RequestLatency"
  namespace           = "AWS/AppRunner"
  period              = "60"
  statistic           = "p95"
  threshold           = "3000"  # 3 seconds p95 latency threshold
  alarm_description   = "API p95 latency exceeded 3 seconds"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ServiceName = aws_apprunner_service.grahvani_api.service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "grahvani-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5xxStatusResponses"
  namespace           = "AWS/AppRunner"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "More than 10 HTTP 5xx errors in 1 minute"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ServiceName = aws_apprunner_service.grahvani_api.service_name
  }
}