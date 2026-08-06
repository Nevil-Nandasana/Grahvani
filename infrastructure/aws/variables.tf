# Terraform Variables for Grahvani Infrastructure
# All configurable values for the AWS infrastructure deployment.
# Set sensitive values via environment variables (TF_VAR_<name>) or
# a terraform.tfvars file that is NOT committed to version control.

# ─── Region & Networking ──────────────────────────────────────────────────────
variable "aws_region" {
  description = "AWS region for all resource deployment (Mumbai for India latency)"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH into the bastion host. Restrict to your office IP in production."
  type        = list(string)
  default     = ["0.0.0.0/0"] # IMPORTANT: restrict this before going live!
}

# ─── Database ────────────────────────────────────────────────────────────────
variable "db_master_username" {
  description = "Master username for the RDS Aurora PostgreSQL cluster"
  type        = string
  default     = "grahvani_admin"
}

variable "db_master_password" {
  description = "Master password for the RDS Aurora cluster. Set via TF_VAR_db_master_password."
  type        = string
  sensitive   = true
}

# ─── Redis ───────────────────────────────────────────────────────────────────
variable "redis_auth_token" {
  description = "Redis AUTH token for ElastiCache TLS. Set via TF_VAR_redis_auth_token. Min 16 chars."
  type        = string
  sensitive   = true
}

# ─── Google AI ───────────────────────────────────────────────────────────────
variable "gemini_api_key" {
  description = "Google Gemini API key for AI interpretation. Set via TF_VAR_gemini_api_key."
  type        = string
  sensitive   = true
}

# ─── Razorpay ────────────────────────────────────────────────────────────────
variable "razorpay_key_id" {
  description = "Razorpay Key ID for payment processing. Set via TF_VAR_razorpay_key_id."
  type        = string
  sensitive   = true
}

variable "razorpay_key_secret" {
  description = "Razorpay Key Secret. Set via TF_VAR_razorpay_key_secret."
  type        = string
  sensitive   = true
}

variable "razorpay_webhook_secret" {
  description = "Razorpay Webhook HMAC secret for validating webhook payloads."
  type        = string
  sensitive   = true
}

# ─── Apple App Store ─────────────────────────────────────────────────────────
variable "apple_bundle_id" {
  description = "Apple App Store Bundle ID"
  type        = string
  default     = "com.grahvani.app"
}

variable "apple_shared_secret" {
  description = "Apple App Store Shared Secret. Set via TF_VAR_apple_shared_secret."
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
  description = "Apple App Store Connect API Private Key PEM. Set via TF_VAR_apple_private_key."
  type        = string
  sensitive   = true
}

# ─── Google Play ─────────────────────────────────────────────────────────────
variable "google_service_account_path" {
  description = "Local path to Google Play service account JSON (only needed for initial tf apply)"
  type        = string
  default     = "./google-play-service-account.json"
}

variable "firebase_service_account_path" {
  description = "Local path to Firebase service account JSON (only needed for initial tf apply)"
  type        = string
  default     = "./firebase-service-account.json"
}

# ─── Application ─────────────────────────────────────────────────────────────
variable "app_secret_key" {
  description = "Application secret key for JWT signing and session encryption. 32+ random chars."
  type        = string
  sensitive   = true
}

variable "google_places_api_key" {
  description = "Google Places API key for birth place geocoding"
  type        = string
  sensitive   = true
}

# ─── AI Observability ────────────────────────────────────────────────────────
variable "langfuse_secret_key" {
  description = "Langfuse secret key for AI trace logging. Set via TF_VAR_langfuse_secret_key."
  type        = string
  sensitive   = true
  default     = ""
}

variable "langfuse_public_key" {
  description = "Langfuse public key for AI trace logging."
  type        = string
  default     = ""
}

variable "langfuse_host" {
  description = "Langfuse host URL (e.g. https://cloud.langfuse.com)"
  type        = string
  default     = "https://cloud.langfuse.com"
}

# ─── S3 ──────────────────────────────────────────────────────────────────────
variable "aws_s3_bucket_prefix" {
  description = "Globally unique prefix for S3 bucket names (e.g. grahvani-prod)"
  type        = string
  default     = "grahvani-prod"
}