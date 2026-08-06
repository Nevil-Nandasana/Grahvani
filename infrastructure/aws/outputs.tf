# Grahvani — Terraform Outputs
# All infrastructure outputs used by CI/CD, application config, and operations.
# Extracted here from variables.tf to follow Terraform best practice.

# ─── Networking ───────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "ID of the Grahvani production VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the Grahvani production VPC"
  value       = aws_vpc.main.cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the three private subnets (one per AZ)"
  value = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
    aws_subnet.private_c.id,
  ]
}

output "public_subnet_ids" {
  description = "IDs of the three public subnets (one per AZ)"
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
    aws_subnet.public_c.id,
  ]
}

# ─── Database (RDS Aurora) ───────────────────────────────────────────────────
output "rds_cluster_endpoint" {
  description = "Writer endpoint for the RDS Aurora PostgreSQL cluster"
  value       = aws_rds_cluster.grahvani.endpoint
  sensitive   = true
}

output "rds_reader_endpoint" {
  description = "Reader endpoint for the RDS Aurora PostgreSQL cluster (load-balanced)"
  value       = aws_rds_cluster.grahvani.reader_endpoint
  sensitive   = true
}

output "rds_cluster_identifier" {
  description = "Identifier of the RDS cluster"
  value       = aws_rds_cluster.grahvani.cluster_identifier
}

output "rds_database_name" {
  description = "Name of the PostgreSQL database"
  value       = aws_rds_cluster.grahvani.database_name
}

output "rds_port" {
  description = "Port number of the RDS cluster"
  value       = aws_rds_cluster.grahvani.port
}

# ─── Redis (ElastiCache) ─────────────────────────────────────────────────────
output "redis_primary_endpoint" {
  description = "Primary endpoint for the ElastiCache Redis cluster"
  value       = aws_elasticache_replication_group.grahvani.primary_endpoint_address
  sensitive   = true
}

output "redis_reader_endpoint" {
  description = "Reader endpoint for the ElastiCache Redis cluster"
  value       = aws_elasticache_replication_group.grahvani.reader_endpoint_address
  sensitive   = true
}

output "redis_port" {
  description = "Port number of the Redis cluster"
  value       = 6379
}

# ─── Container Registry (ECR) ─────────────────────────────────────────────────
output "ecr_repository_url" {
  description = "ECR repository URL for Docker images"
  value       = aws_ecr_repository.grahvani.repository_url
}

output "ecr_registry_id" {
  description = "ECR registry ID (AWS account ID)"
  value       = aws_ecr_repository.grahvani.registry_id
}

# ─── App Runner ───────────────────────────────────────────────────────────────
output "apprunner_api_service_url" {
  description = "App Runner API service URL (HTTPS)"
  value       = "https://${aws_apprunner_service.grahvani_api.service_url}"
}

output "apprunner_api_service_arn" {
  description = "App Runner API service ARN"
  value       = aws_apprunner_service.grahvani_api.arn
}

output "apprunner_worker_service_arn" {
  description = "App Runner Dramatiq Worker service ARN"
  value       = aws_apprunner_service.grahvani_worker.arn
}

# ─── S3 Buckets ───────────────────────────────────────────────────────────────
output "s3_curated_sources_bucket_name" {
  description = "S3 bucket name for curated astrological source texts"
  value       = aws_s3_bucket.curated_sources.id
}

output "s3_curated_sources_bucket_arn" {
  description = "S3 bucket ARN for curated astrological source texts"
  value       = aws_s3_bucket.curated_sources.arn
}

output "s3_pdf_exports_bucket_name" {
  description = "S3 bucket name for generated PDF birth chart exports"
  value       = aws_s3_bucket.pdf_exports.id
}

output "s3_pdf_exports_bucket_arn" {
  description = "S3 bucket ARN for generated PDF birth chart exports"
  value       = aws_s3_bucket.pdf_exports.arn
}

# ─── Secrets Manager ARNs ─────────────────────────────────────────────────────
# These ARNs are used by CI/CD to inject secrets into App Runner runtime.

output "secret_arn_db_credentials" {
  description = "Secrets Manager ARN for database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
  sensitive   = true
}

output "secret_arn_redis_auth" {
  description = "Secrets Manager ARN for Redis auth token"
  value       = aws_secretsmanager_secret.redis_auth.arn
  sensitive   = true
}

output "secret_arn_gemini_api_key" {
  description = "Secrets Manager ARN for Google Gemini API key"
  value       = aws_secretsmanager_secret.gemini_api_key.arn
  sensitive   = true
}

output "secret_arn_razorpay" {
  description = "Secrets Manager ARN for Razorpay credentials"
  value       = aws_secretsmanager_secret.razorpay.arn
  sensitive   = true
}

output "secret_arn_app_secret" {
  description = "Secrets Manager ARN for application secret key"
  value       = aws_secretsmanager_secret.app_secret.arn
  sensitive   = true
}

# ─── KMS Keys ────────────────────────────────────────────────────────────────
output "kms_key_arn_rds" {
  description = "KMS key ARN used for RDS encryption"
  value       = aws_kms_key.rds.arn
  sensitive   = true
}

output "kms_key_arn_secretsmanager" {
  description = "KMS key ARN used for Secrets Manager encryption"
  value       = aws_kms_key.secretsmanager.arn
  sensitive   = true
}

# ─── IAM Roles ───────────────────────────────────────────────────────────────
output "iam_role_arn_apprunner" {
  description = "IAM role ARN for App Runner service (ECR + Secrets Manager access)"
  value       = aws_iam_role.apprunner_service_role.arn
}

# ─── Monitoring ──────────────────────────────────────────────────────────────
output "sns_topic_arn_alerts" {
  description = "SNS topic ARN for infrastructure alerts (RDS, Redis, App Runner)"
  value       = aws_sns_topic.alerts.arn
}

# ─── Convenience Outputs for CI/CD ───────────────────────────────────────────
output "aws_region" {
  description = "AWS region where all resources are deployed"
  value       = var.aws_region
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
