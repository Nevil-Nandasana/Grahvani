# Terraform Variables for Grahvani Infrastructure
# All configurable values for the AWS infrastructure deployment.

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1"  # Mumbai
}

variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_master_username" {
  description = "Master username for RDS database"
  type        = string
  default     = "grahvani_admin"
}

variable "db_master_password" {
  description = "Master password for RDS database (should be set via environment variable)"
  type        = string
  sensitive   = true
}

variable "redis_auth_token" {
  description = "Redis auth token for ElastiCache (should be set via environment variable)"
  type        = string
  sensitive   = true
}

variable "gemini_api_key" {
  description = "Google Gemini API key for AI interpretation (should be set via environment variable)"
  type        = string
  sensitive   = true
}

variable "razorpay_key_id" {
  description = "Razorpay Key ID (should be set via environment variable)"
  type        = string
  sensitive   = true
}

variable "razorpay_key_secret" {
  description = "Razorpay Key Secret (should be set via environment variable)"
  type        = string
  sensitive   = true
}

variable "razorpay_webhook_secret" {
  description = "Razorpay Webhook Secret for HMAC validation (should be set via environment variable)"
  type        = string
  sensitive   = true
}

variable "google_service_account_path" {
  description = "Path to Google Play service account JSON file"
  type        = string
  default     = "./google-play-service-account.json"
}

variable "firebase_service_account_path" {
  description = "Path to Firebase service account JSON file"
  type        = string
  default     = "./firebase-service-account.json"
}

variable "apple_bundle_id" {
  description = "Apple App Store Bundle ID"
  type        = string
  default     = "com.grahvani.app"
}

variable "apple_shared_secret" {
  description = "Apple App Store Shared Secret (should be set via environment variable)"
  type        = string
  sensitive   = true
}

variable "apple_key_id" {
  description = "Apple App Store Connect API Key ID"
  type        = string
  default     = ""
}

variable "apple_issuer_id" {
  description = "Apple App Store Connect API Issuer ID"
  type        = string
  default     = ""
}

variable "apple_private_key" {
  description = "Apple App Store Connect API Private Key (should be set via environment variable)"
  type        = string
  sensitive   = true
}

variable "app_secret_key" {
  description = "Application secret key for JWT signing (should be set via environment variable)"
  type        = string
  sensitive   = true
}

variable "google_places_api_key" {
  description = "Google Places API key for geocoding (should be set via environment variable)"
  type        = string
  sensitive   = true
}

variable "aws_s3_bucket_prefix" {
  description = "Prefix for S3 bucket names (must be globally unique)"
  type        = string
  default     = "grahvani-prod"
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to access bastion host via SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict in production!
}

# Output variables
output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.main.id
}

output "rds_endpoint" {
  description = "RDS cluster endpoint"
  value       = aws_rds_cluster.grahvani.endpoint
  sensitive   = true
}

output "redis_primary_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = aws_elasticache_replication_group.grahvani.primary_endpoint_address
  sensitive   = true
}

output "redis_reader_endpoint" {
  description = "ElastiCache Redis reader endpoint"
  value       = aws_elasticache_replication_group.grahvani.reader_endpoint_address
  sensitive   = true
}

output "s3_curated_sources_bucket" {
  description = "S3 bucket for curated sources"
  value       = aws_s3_bucket.curated_sources.id
}

output "s3_pdf_exports_bucket" {
  description = "S3 bucket for PDF exports"
  value       = aws_s3_bucket.pdf_exports.id
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.grahvani.repository_url
}

output "apprunner_service_url" {
  description = "App Runner service URL"
  value       = aws_apprunner_service.grahvani_api.service_url
}