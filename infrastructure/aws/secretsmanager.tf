# AWS Secrets Manager for Grahvani
# Secure storage for all application secrets with KMS encryption and automated rotation.
# Every secret is encrypted with a dedicated CMK (Customer Managed Key).
# The App Runner runtime receives secrets as environment variables via SM ARN references.

# ─── KMS Key for Secrets Manager ─────────────────────────────────────────────
resource "aws_kms_key" "secretsmanager" {
  description             = "KMS CMK for encrypting all Grahvani Secrets Manager secrets"
  deletion_window_in_days = 30
  enable_key_rotation     = true  # Automatic annual key rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Root account has full key management
      {
        Sid    = "AllowRootAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # Secrets Manager can use the key for encrypt/decrypt operations
      {
        Sid    = "AllowSecretsManagerAccess"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      # App Runner instance role can use the key to decrypt secrets
      {
        Sid    = "AllowAppRunnerInstanceDecrypt"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.apprunner_instance_role.arn
        }
        Action = [
          "kms:Decrypt",
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

resource "aws_kms_alias" "secretsmanager" {
  name          = "alias/grahvani-secretsmanager"
  target_key_id = aws_kms_key.secretsmanager.key_id
}

# ─── Database Credentials ─────────────────────────────────────────────────────
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "grahvani/db/credentials"
  description             = "RDS Aurora PostgreSQL master credentials for Grahvani"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn

  tags = {
    Name       = "grahvani-db-credentials"
    SecretType = "database"
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
    # Full DSN for SQLAlchemy asyncpg driver
    database_url = "postgresql+asyncpg://${var.db_master_username}:${var.db_master_password}@${aws_rds_cluster.grahvani.endpoint}:5432/grahvani"
  })

  # Re-create the version when RDS endpoint changes (e.g., cluster replacement).
  lifecycle {
    ignore_changes = [secret_string]  # Managed by rotation Lambda post-deploy
  }
}

# ─── Redis Auth Token ─────────────────────────────────────────────────────────
resource "aws_secretsmanager_secret" "redis_auth" {
  name                    = "grahvani/redis/auth-token"
  description             = "Redis AUTH token for ElastiCache TLS authentication"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn

  tags = {
    Name       = "grahvani-redis-auth"
    SecretType = "redis"
  }
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = var.redis_auth_token
}

# ─── Google Gemini API Key ─────────────────────────────────────────────────────
resource "aws_secretsmanager_secret" "gemini_api_key" {
  name                    = "grahvani/gemini/api-key"
  description             = "Google Gemini API key for AI interpretation pipeline"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn

  tags = {
    Name       = "grahvani-gemini-api-key"
    SecretType = "api-key"
  }
}

resource "aws_secretsmanager_secret_version" "gemini_api_key" {
  secret_id     = aws_secretsmanager_secret.gemini_api_key.id
  secret_string = var.gemini_api_key
}

# ─── Razorpay Credentials ─────────────────────────────────────────────────────
resource "aws_secretsmanager_secret" "razorpay" {
  name                    = "grahvani/razorpay/credentials"
  description             = "Razorpay API credentials for India payment processing"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn

  tags = {
    Name       = "grahvani-razorpay-credentials"
    SecretType = "payment"
  }
}

resource "aws_secretsmanager_secret_version" "razorpay" {
  secret_id = aws_secretsmanager_secret.razorpay.id
  secret_string = jsonencode({
    key_id          = var.razorpay_key_id
    key_secret      = var.razorpay_key_secret
    webhook_secret  = var.razorpay_webhook_secret
  })
}

# ─── Google Play Service Account ──────────────────────────────────────────────
resource "aws_secretsmanager_secret" "google_play" {
  name                    = "grahvani/google-play/service-account"
  description             = "Google Play service account JSON for RTDN webhook verification"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn

  tags = {
    Name       = "grahvani-google-play-service-account"
    SecretType = "service-account"
  }
}

resource "aws_secretsmanager_secret_version" "google_play" {
  secret_id     = aws_secretsmanager_secret.google_play.id
  secret_string = file(var.google_service_account_path)
}

# ─── Apple App Store Credentials ──────────────────────────────────────────────
resource "aws_secretsmanager_secret" "apple_app_store" {
  name                    = "grahvani/apple/app-store"
  description             = "Apple App Store Server Notifications v2 credentials"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn

  tags = {
    Name       = "grahvani-apple-app-store"
    SecretType = "apple"
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

# ─── Firebase Service Account ─────────────────────────────────────────────────
resource "aws_secretsmanager_secret" "firebase" {
  name                    = "grahvani/firebase/service-account"
  description             = "Firebase Admin SDK service account for JWT verification"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn

  tags = {
    Name       = "grahvani-firebase-service-account"
    SecretType = "service-account"
  }
}

resource "aws_secretsmanager_secret_version" "firebase" {
  secret_id     = aws_secretsmanager_secret.firebase.id
  secret_string = file(var.firebase_service_account_path)
}

# ─── Application Secret Key ───────────────────────────────────────────────────
resource "aws_secretsmanager_secret" "app_secret" {
  name                    = "grahvani/app/secret-key"
  description             = "Application secret key for JWT signing and session encryption"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn

  tags = {
    Name       = "grahvani-app-secret-key"
    SecretType = "app"
  }
}

resource "aws_secretsmanager_secret_version" "app_secret" {
  secret_id     = aws_secretsmanager_secret.app_secret.id
  secret_string = var.app_secret_key
}

# ─── Google Places API Key ────────────────────────────────────────────────────
resource "aws_secretsmanager_secret" "google_places" {
  name                    = "grahvani/google-places/api-key"
  description             = "Google Places API key for birth place geocoding"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn

  tags = {
    Name       = "grahvani-google-places-api-key"
    SecretType = "api-key"
  }
}

resource "aws_secretsmanager_secret_version" "google_places" {
  secret_id     = aws_secretsmanager_secret.google_places.id
  secret_string = var.google_places_api_key
}

# ─── Langfuse AI Observability ───────────────────────────────────────────────
resource "aws_secretsmanager_secret" "langfuse" {
  name                    = "grahvani/langfuse/credentials"
  description             = "Langfuse credentials for AI trace logging and cost accounting"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.secretsmanager.arn

  tags = {
    Name       = "grahvani-langfuse-credentials"
    SecretType = "observability"
  }
}

resource "aws_secretsmanager_secret_version" "langfuse" {
  secret_id = aws_secretsmanager_secret.langfuse.id
  secret_string = jsonencode({
    secret_key = var.langfuse_secret_key
    public_key = var.langfuse_public_key
    host       = var.langfuse_host
  })
}

# ─── IAM Policy: App Runner reads Secrets Manager ────────────────────────────
resource "aws_iam_policy" "secretsmanager_read" {
  name        = "grahvani-secretsmanager-read-policy"
  description = "Allows Grahvani App Runner instance role to read all application secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadApplicationSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
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
          aws_secretsmanager_secret.langfuse.arn,
        ]
      },
      {
        Sid    = "DecryptSecretsWithCMK"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.secretsmanager.arn
        ]
      }
    ]
  })
}

# Attach Secrets Manager read policy to the App Runner SERVICE role (for env secret injection)
resource "aws_iam_role_policy_attachment" "apprunner_secretsmanager" {
  role       = aws_iam_role.apprunner_service_role.name
  policy_arn = aws_iam_policy.secretsmanager_read.arn
}

# Also attach to the INSTANCE role (for runtime SDK calls from app code)
resource "aws_iam_role_policy_attachment" "apprunner_instance_secretsmanager" {
  role       = aws_iam_role.apprunner_instance_role.name
  policy_arn = aws_iam_policy.secretsmanager_read.arn
}

# ─── Lambda: Database Password Rotation ──────────────────────────────────────
# Implements the standard 4-step Secrets Manager rotation protocol.

# Package the rotation Lambda from local source using the archive provider.
data "archive_file" "rotate_db_password" {
  type        = "zip"
  source_file = "${path.module}/lambda/rotate_db_password.py"
  output_path = "${path.module}/lambda/rotate_db_password.zip"
}

resource "aws_lambda_function" "rotate_db_password" {
  filename         = data.archive_file.rotate_db_password.output_path
  source_code_hash = data.archive_file.rotate_db_password.output_base64sha256
  function_name    = "grahvani-rotate-db-password"
  role             = aws_iam_role.lambda_secretsmanager.arn
  handler          = "rotate_db_password.handler"
  runtime          = "python3.12"
  timeout          = 300

  environment {
    variables = {
      SECRET_ARN    = aws_secretsmanager_secret.db_credentials.arn
      DB_HOST       = aws_rds_cluster.grahvani.endpoint
      DB_PORT       = "5432"
      DB_NAME       = "grahvani"
    }
  }

  # Lambda must be in the VPC to connect to RDS
  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id, aws_subnet.private_c.id]
    security_group_ids = [aws_security_group.lambda_rotation.id]
  }

  tags = {
    Name = "grahvani-rotate-db-password"
  }
}

# Allow Secrets Manager to invoke the Lambda rotation function
resource "aws_lambda_permission" "secretsmanager_invoke_rotation" {
  statement_id  = "AllowSecretsManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotate_db_password.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = aws_secretsmanager_secret.db_credentials.arn
}

# ─── Automatic Rotation Schedule ─────────────────────────────────────────────
resource "aws_secretsmanager_secret_rotation" "db_credentials" {
  secret_id           = aws_secretsmanager_secret.db_credentials.id
  rotation_lambda_arn = aws_lambda_function.rotate_db_password.arn

  rotation_rules {
    automatically_after_days = 30
  }

  depends_on = [aws_lambda_permission.secretsmanager_invoke_rotation]
}

# ─── IAM Role for Lambda Rotation ────────────────────────────────────────────
resource "aws_iam_role" "lambda_secretsmanager" {
  name = "grahvani-lambda-rotation-role"

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

  tags = {
    Name = "grahvani-lambda-rotation-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_secretsmanager.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_secretsmanager.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_policy" "lambda_rotation_custom" {
  name        = "grahvani-lambda-rotation-custom"
  description = "Allows the rotation Lambda to read/write the DB credentials secret and update RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageDbSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
          "secretsmanager:DescribeSecret",
        ]
        Resource = aws_secretsmanager_secret.db_credentials.arn
      },
      {
        Sid    = "UpdateRdsPassword"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:ModifyDBCluster",
        ]
        Resource = aws_rds_cluster.grahvani.arn
      },
      {
        Sid    = "UseKmsKey"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.secretsmanager.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_rotation_custom" {
  role       = aws_iam_role.lambda_secretsmanager.name
  policy_arn = aws_iam_policy.lambda_rotation_custom.arn
}

# ─── Security Group: Lambda Rotation ─────────────────────────────────────────
resource "aws_security_group" "lambda_rotation" {
  name        = "grahvani-lambda-rotation-sg"
  description = "Security group for the DB password rotation Lambda"
  vpc_id      = aws_vpc.main.id

  # Lambda needs HTTPS to call Secrets Manager VPC endpoint
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to Secrets Manager VPC endpoint"
  }

  # Lambda needs PostgreSQL to update the RDS password
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "PostgreSQL to RDS cluster"
  }

  tags = {
    Name = "grahvani-lambda-rotation-sg"
  }
}