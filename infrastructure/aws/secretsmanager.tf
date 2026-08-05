# AWS Secrets Manager for Grahvani
# Secure storage for API keys, database passwords, and sensitive configuration.

# Database credentials secret
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "grahvani/db/credentials"
  description             = "Database master credentials for Grahvani RDS"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn
  
  tags = {
    Name        = "grahvani-db-credentials"
    Environment = "production"
    Project     = "Grahvani"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_master_username
    password = var.db_master_password
    engine   = "postgres"
    host     = aws_rds_cluster.grahvani.endpoint
    port     = 5432
    dbname   = "grahvani"
  })
}

# Redis auth token secret
resource "aws_secretsmanager_secret" "redis_auth" {
  name                    = "grahvani/redis/auth-token"
  description             = "Redis auth token for ElastiCache"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn
  
  tags = {
    Name        = "grahvani-redis-auth"
    Environment = "production"
    Project     = "Grahvani"
  }
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id = aws_secretsmanager_secret.redis_auth.id
  secret_string = var.redis_auth_token
}

# Google Gemini API key secret
resource "aws_secretsmanager_secret" "gemini_api_key" {
  name                    = "grahvani/gemini/api-key"
  description             = "Google Gemini API key for AI interpretation"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn
  
  tags = {
    Name        = "grahvani-gemini-api-key"
    Environment = "production"
    Project     = "Grahvani"
  }
}

resource "aws_secretsmanager_secret_version" "gemini_api_key" {
  secret_id = aws_secretsmanager_secret.gemini_api_key.id
  secret_string = var.gemini_api_key
}

# Razorpay credentials secret
resource "aws_secretsmanager_secret" "razorpay" {
  name                    = "grahvani/razorpay/credentials"
  description             = "Razorpay API credentials for payment processing"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn
  
  tags = {
    Name        = "grahvani-razorpay-credentials"
    Environment = "production"
    Project     = "Grahvani"
  }
}

resource "aws_secretsmanager_secret_version" "razorpay" {
  secret_id = aws_secretsmanager_secret.razorpay.id
  secret_string = jsonencode({
    key_id       = var.razorpay_key_id
    key_secret   = var.razorpay_key_secret
    webhook_secret = var.razorpay_webhook_secret
  })
}

# Google Play service account secret
resource "aws_secretsmanager_secret" "google_play" {
  name                    = "grahvani/google-play/service-account"
  description             = "Google Play service account JSON for RTDN"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn
  
  tags = {
    Name        = "grahvani-google-play-service-account"
    Environment = "production"
    Project     = "Grahvani"
  }
}

resource "aws_secretsmanager_secret_version" "google_play" {
  secret_id = aws_secretsmanager_secret.google_play.id
  secret_string = file(var.google_service_account_path)
}

# Apple App Store credentials secret
resource "aws_secretsmanager_secret" "apple_app_store" {
  name                    = "grahvani/apple/app-store"
  description             = "Apple App Store Server Notifications credentials"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn
  
  tags = {
    Name        = "grahvani-apple-app-store"
    Environment = "production"
    Project     = "Grahvani"
  }
}

resource "aws_secretsmanager_secret_version" "apple_app_store" {
  secret_id = aws_secretsmanager_secret.apple_app_store.id
  secret_string = jsonencode({
    bundle_id     = var.apple_bundle_id
    shared_secret = var.apple_shared_secret
    key_id        = var.apple_key_id
    issuer_id     = var.apple_issuer_id
    private_key   = var.apple_private_key
  })
}

# Firebase service account secret
resource "aws_secretsmanager_secret" "firebase" {
  name                    = "grahvani/firebase/service-account"
  description             = "Firebase service account for JWT verification"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn
  
  tags = {
    Name        = "grahvani-firebase-service-account"
    Environment = "production"
    Project     = "Grahvani"
  }
}

resource "aws_secretsmanager_secret_version" "firebase" {
  secret_id = aws_secretsmanager_secret.firebase.id
  secret_string = file(var.firebase_service_account_path)
}

# Application secret key (JWT signing, session encryption)
resource "aws_secretsmanager_secret" "app_secret" {
  name                    = "grahvani/app/secret-key"
  description             = "Application secret key for JWT signing and encryption"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn
  
  tags = {
    Name        = "grahvani-app-secret-key"
    Environment = "production"
    Project     = "Grahvani"
  }
}

resource "aws_secretsmanager_secret_version" "app_secret" {
  secret_id = aws_secretsmanager_secret.app_secret.id
  secret_string = var.app_secret_key
}

# Google Places API key secret
resource "aws_secretsmanager_secret" "google_places" {
  name                    = "grahvani/google-places/api-key"
  description             = "Google Places API key for geocoding"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn
  
  tags = {
    Name        = "grahvani-google-places-api-key"
    Environment = "production"
    Project     = "Grahvani"
  }
}

resource "aws_secretsmanager_secret_version" "google_places" {
  secret_id = aws_secretsmanager_secret.google_places.id
  secret_string = var.google_places_api_key
}

# KMS Key for Secrets Manager encryption
resource "aws_kms_key" "secretsmanager" {
  description             = "KMS key for Grahvani Secrets Manager encryption"
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
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Name = "grahvani-secretsmanager-kms-key"
  }
}

# IAM Policy for App Runner to read secrets
resource "aws_iam_policy" "secretsmanager_read" {
  name        = "grahvani-secretsmanager-read-policy"
  description = "Policy for Grahvani App Runner to read secrets from Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = [
          aws_secretsmanager_secret.db_credentials.arn,
          aws_secretsmanager_secret.redis_auth.arn,
          aws_secretsmanager_secret.gemini_api_key.arn,
          aws_secretsmanager_secret.razorpay.arn,
          aws_secretsmanager_secret.google_play.arn,
          aws_secretsmanager_secret.apple_app_store.arn,
          aws_secretsmanager_secret.firebase.arn,
          aws_secretsmanager_secret.app_secret.arn,
          aws_secretsmanager_secret.google_places.arn,
        ]
      }
    ]
  })
}

# Attach Secrets Manager policy to App Runner role
resource "aws_iam_role_policy_attachment" "apprunner_secretsmanager" {
  role       = aws_iam_role.apprunner_service_role.name
  policy_arn = aws_iam_policy.secretsmanager_read.arn
}

# Automatic rotation for database credentials (using Lambda)
resource "aws_secretsmanager_secret_rotation" "db_credentials" {
  secret_id           = aws_secretsmanager_secret.db_credentials.id
  rotation_lambda_arn = aws_lambda_function.rotate_db_password.arn
  rotation_rules {
    automatically_after_days = 30
  }
}

# Lambda function for rotating database password
resource "aws_lambda_function" "rotate_db_password" {
  filename         = "lambda/rotate_db_password.zip"
  function_name    = "grahvani-rotate-db-password"
  role             = aws_iam_role.lambda_secretsmanager.arn
  handler          = "rotate_db_password.handler"
  runtime          = "python3.12"
  timeout          = 300
  
  environment {
    variables = {
      SECRET_ARN = aws_secretsmanager_secret.db_credentials.arn
    }
  }
  
  tags = {
    Name = "grahvani-rotate-db-password"
  }
}

# IAM Role for Lambda rotation
resource "aws_iam_role" "lambda_secretsmanager" {
  name = "grahvani-lambda-secretsmanager-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secretsmanager_basic" {
  role       = aws_iam_role.lambda_secretsmanager.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_secretsmanager_rds" {
  role       = aws_iam_role.lambda_secretsmanager.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSDataFullAccess"
}

resource "aws_iam_policy" "lambda_secretsmanager_custom" {
  name        = "grahvani-lambda-secretsmanager-custom"
  description = "Custom policy for Lambda to rotate RDS password"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
          "secretsmanager:DescribeSecret",
          "rds:DescribeDBClusters",
          "rds:ModifyDBCluster"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secretsmanager_custom" {
  role       = aws_iam_role.lambda_secretsmanager.name
  policy_arn = aws_iam_policy.lambda_secretsmanager_custom.arn
}